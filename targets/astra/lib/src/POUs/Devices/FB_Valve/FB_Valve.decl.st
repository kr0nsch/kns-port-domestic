// Назначение: запорная арматура двух видов. Задвижка с электроприводом (Motorized): выходы
//             «открывать» и «закрывать», стоп в промежутке, смена направления в ходе — через паузу
//             tReverse. Клапан с соленоидом (SolenoidEto, SolenoidEtc): одна катушка, пружинный
//             возврат. Открыть, закрыть, стоп от HMI и от автоматики; концевики ZSO/ZSC (или
//             положение по времени хода), контроль времени хода, «оба концевика», уход с концевика,
//             муфта ограничения момента, внешняя авария; Reset с окном tResetWindow; блокировки с
//             положением безопасности и первопричиной, разрешения по направлениям; режимы Auto,
//             Manual, Local, OutOfService; циклы и время работы привода в stRetain. Блокировка при одних
//             отказах контроля ведёт задвижку в положение безопасности (VLV-20); муфта открытия при
//             страгивании с седла — не заклинивание (VLV-21). Наследует FB_DeviceBase: тело — нормативный
//             порядок цикла (раздел 9.4 контракта).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
FUNCTION_BLOCK FB_Valve EXTENDS FB_DeviceBase
VAR_INPUT
    xAutoOpen    : BOOL;             // запрос автоматики: TRUE — открыть, FALSE — закрыть
    xZso         : BOOL;             // концевик «открыто»
    xZsc         : BOOL;             // концевик «закрыто»
    xTorqueOpen  : BOOL;             // муфта (моментный выключатель) в сторону открытия
    xTorqueClose : BOOL;             // муфта в сторону закрытия
    xExtFault    : BOOL;             // авария привода: тепловое реле, обрыв фазы, авария интегрированного привода
    xLocal       : BOOL;             // «Местное» на приводе или шкафу
    xPowerOk     : BOOL := TRUE;     // напряжение питания привода
    wInterlock   : WORD := 16#0000;  // блокировки: бит = 1 — вести в eSafePos
    wPermitOpen  : WORD := 16#FFFF;  // разрешения на открытие: бит = 1 — разрешено
    wPermitClose : WORD := 16#FFFF;  // разрешения на закрытие: бит = 1 — разрешено
END_VAR
VAR_IN_OUT
    stCmd    : ST_ValveCmd;          // команды HMI/SCADA (GVL_Hmi.st<TAG>Cmd)
    stRetain : ST_DeviceRetain;      // режим, OOS, циклы, время работы привода (GVL_Persist.st<TAG>Retain)
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_ValveCfg;             // параметры (GVL_Persist.st<TAG>Cfg)
END_VAR
VAR_OUTPUT
    xQOpen  : BOOL;                  // Motorized: контактор «открывать»; соленоид — FALSE
    xQClose : BOOL;                  // Motorized: контактор «закрывать»; соленоид — FALSE
    xQCoil  : BOOL;                  // соленоид: катушка; Motorized — FALSE
    xOpened : BOOL;                  // положение «открыто» (по концевику или по времени хода)
    xClosed : BOOL;                  // положение «закрыто»
    stSts   : ST_ValveSts;           // состояние для HMI/SCADA
END_VAR
VAR
    stCfgLkg     : ST_ValveCfg;      // последняя корректная конфигурация (LKG, нормативно)
    // --- состояние и цель ---
    eState       : E_ValveState := E_ValveState.Unknown;        // состояние арматуры
    eTarget      : E_ValveState := E_ValveState.Intermediate;   // цель вызова: Open, Closed; Intermediate — «никуда»
    eManTarget   : E_ValveState := E_ValveState.Intermediate;   // цель Manual: последняя команда оператора
    eSolCmd      : E_ValveState := E_ValveState.Intermediate;  // соленоид: куда держит катушка; Intermediate — нет тока
    eLastEnd     : E_ValveState := E_ValveState.Unknown;        // последнее достигнутое крайнее положение (счёт циклов)
    eLastDir     : E_ValveState := E_ValveState.Intermediate;   // последнее включённое направление привода (выбег)
    xEndByLs     : BOOL;            // положение Open/Closed подтверждено своим концевиком (контроль ухода)
    // --- отказы: фиксируются до Reset (BothLimits — нет) ---
    xFltFailOpen  : BOOL;            // не открылась за tTravel
    xFltFailClose : BOOL;            // не закрылась за tTravel
    xFltPosLost   : BOOL;            // уход с концевика без команды
    xFltTorque    : BOOL;            // муфта в ходе
    xFltExt       : BOOL;            // внешняя авария
    xBothLimits   : BOOL;            // оба концевика дольше tLimitFilter (не фиксируется)
    xResetWin     : BOOL;            // идёт окно Reset: отказы снимаются, как только ушла причина
    // --- блокировки ---
    wIlkPrev      : WORD;            // блокировки после маски в прошлом вызове (первопричина)
    uiFirstOut    : UINT := GVL_Const.NO_FIRST_OUT;   // номер бита первой блокировки; NO_FIRST_OUT — нет
    // --- время работы привода ---
    xActPrev      : BOOL;            // в прошлом вызове был включён выход привода
    ltActAccum    : LTIME;           // накопитель времени работы привода: доля, меньшая 1 с
    // --- задержки (FB_Delay — единственный таймер библиотеки) ---
    fbTravel      : FB_Delay;        // время хода tTravel: от включения выхода (у соленоида — от смены цели)
    fbReverse     : FB_Delay;        // пауза перед реверсом tReverse
    fbRunOff      : FB_Delay;        // выбег привода: TRUE, пока выход включён, и ещё tReverse после снятия
    fbBoth        : FB_Delay;        // фильтр «оба концевика» tLimitFilter
    fbPosLost     : FB_Delay;        // фильтр ухода с концевика tLimitFilter
    fbResetWin    : FB_Delay;        // окно Reset tResetWindow
    // --- аварийный ход в положение безопасности при отказе контроля (VLV-20) ---
    xSafeMove     : BOOL;            // идёт аварийный ход по блокировке при отказе контроля (Motorized)
    xSafeMoveDone : BOOL;            // аварийный ход закончен: новый — после снятия блокировки или всех отказов
    eSafeDir      : E_ValveState := E_ValveState.Intermediate;   // направление аварийного хода: Opening, Closing
    fbSafeMove    : FB_Delay;        // время аварийного хода tTravel
    // --- страгивание с седла (VLV-21) ---
    xUnseatArmed  : BOOL;            // открытие началось с закрытого положения: муфта при страгивании не отказ
    fbUnseat      : FB_Delay;        // окно страгивания VLV_UNSEAT_BYPASS от начала открытия
    fbZscOff      : FB_Delay;        // ZSC замкнут или разомкнулся меньше tLimitFilter назад
    // --- сигналы и условия этого вызова: считает тело и шаги, читают следующие шаги ---
    xMotorized     : BOOL;           // электропривод (по LKG)
    xAtOpen        : BOOL;           // ZSO подключён и сработал
    xAtClose       : BOOL;           // ZSC подключён и сработал
    xTrqOpen       : BOOL;           // муфта открытия сработала (подключена, Motorized)
    xTrqClose      : BOOL;           // муфта закрытия сработала
    xRemote        : BOOL;           // режим Auto или Manual
    xSupervise     : BOOL;           // контроль концевиков: Auto/Manual и есть корректная Cfg
    xPosSup        : BOOL;           // контроль ухода с концевика: xSupervise и есть напряжение
    wIlk           : WORD;           // блокировки после маски
    xIlkAct        : BOOL;           // блокировка действует (Auto/Manual)
    wPermMissOpen  : WORD;           // недостающие разрешения на открытие
    wPermMissClose : WORD;           // недостающие разрешения на закрытие
    xMayOpen       : BOOL;           // открывать можно: разрешения есть или движение по блокировке
    xMayClose      : BOOL;           // закрывать можно
    xFaultAny      : BOOL;           // есть отказ (фиксированный или «оба концевика»)
    xDrive         : BOOL;           // ПЛК управляет выходами в этом вызове
    xEnterMove     : BOOL;           // в этом вызове началось движение (отсчёт tTravel заново)
END_VAR
VAR_TEMP
    eRes        : E_CmdResult;       // результат ProcessMode
    wPermMiss   : WORD;              // недостающие разрешения для текущего направления
    lrRemain_s  : LREAL;             // остаток времени хода, с
    udiRemain_s : UDINT;             // то же, целые секунды вверх
    xMaint      : BOOL;              // достигнут интервал ТО по циклам
    xAvailDev   : BOOL;              // готовность для автоматики (без учёта Cfg)
    wFltBits    : WORD;              // wFault
    wWrnBits    : WORD;              // wWarning
    wLowBits    : WORD;              // младший байт wStatus
    eDevSt      : E_Ne107Status;     // вклад устройства в NE 107
END_VAR
