// Назначение: двигатель прямого пуска или через УПП (I_Motor). Режимы Auto, Manual, Local,
//             OutOfService; пуск и стоп от HMI и от автоматики; защитные блокировки и разрешения
//             на пуск по маскам с первопричиной; контроль ОС пуска, пропадания ОС в работе,
//             останова и самопроизвольного пуска; внешняя авария (тепловое реле, УПП, ПЧ);
//             Reset с импульсом xQReset и окном снятия причин; минимальные времена работы и паузы,
//             лимит пусков в час; наработка и пуски в stRetain; останов без отказа при пропадании
//             напряжения; подхват работающего двигателя при старте ПЛК. Команда xQRun удерживаемая.
//             Наследник FB_MotorVfd пишет точки расширения до вызова тела через SUPER^(...) и
//             читает результаты (eState, xRunCmd, xEnteredStarting) после него.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Motor.md
FUNCTION_BLOCK FB_Motor EXTENDS FB_DeviceBase IMPLEMENTS I_Motor
VAR_INPUT
    xAutoRun   : BOOL;                 // запрос автоматики «работать» (уровень, не импульс)
    xFbRun     : BOOL;                 // ОС «в работе»: блок-контакт КМ, реле «работа» УПП/ПЧ
    xExtFault  : BOOL;                 // внешняя авария: тепловое реле, автомат, авария УПП
    xLocal     : BOOL;                 // переключатель «Местное»
    xPowerOk   : BOOL := TRUE;         // напряжение на секции шин есть
    wInterlock : WORD := 16#0000;      // защитные блокировки: бит = 1 — блокировка действует
    wPermit    : WORD := 16#FFFF;      // разрешения на пуск: бит = 1 — разрешено
END_VAR
VAR_IN_OUT
    stCmd    : ST_MotorCmd;            // команды HMI/SCADA (GVL_Hmi.st<TAG>Cmd)
    stRetain : ST_DeviceRetain;        // режим, OOS, моточасы, пуски (GVL_Persist.st<TAG>Retain)
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_MotorCfg;               // параметры (GVL_Persist.st<TAG>Cfg)
END_VAR
VAR_OUTPUT
    xQRun    : BOOL;                   // команда «работа» на КМ/УПП/ПЧ (удерживаемая)
    xQReset  : BOOL;                   // импульс сброса аварии УПП/ПЧ по Reset, длительность tResetPulse
    xRunning : BOOL;                   // работает: по ОС; без ОС — по команде; ОС недостоверна — удерживается
                                       // (без питания и при отказе связи — FALSE, VFD-11)
    stSts    : ST_MotorSts;            // состояние для HMI/SCADA
END_VAR
VAR
    stCfgLkg         : ST_MotorCfg;    // последняя корректная конфигурация (LKG; читает FB_MotorVfd)
    // --- точки расширения: пишет наследник ДО SUPER^(...) (нормативно, контракт 13.2) ---
    xFbOverride      : BOOL;           // ОС берётся из xFbOverrideValue вместо xFbRun
    xFbOverrideValue : BOOL;           // значение ОС при xFbOverride
    xFbInvalid       : BOOL;           // ОС недостоверна: контроль ОС приостановлен, таймеры сброшены
    xExtFaultAdd     : BOOL;           // доп. внешняя авария (фиксируется как ExtFault)
    xCommFault       : BOOL;           // нефиксируемый отказ связи: wFault бит 5, eState = Fault
    xStartBlockAdd   : BOOL;           // доп. запрет пуска (ПЧ не готов): PermitMissing, RejectedPermit
    wWarningAdd      : WORD;           // OR в wWarning (биты 2, 6, 8)
    eDevStatusAdd    : E_Ne107Status := E_Ne107Status.Good;   // MAX в eDevStatus
    // --- результаты для наследника: пишет FB_Motor (нормативно) ---
    eState           : E_MotorState := E_MotorState.Stopped;  // состояние двигателя
    xRunCmd          : BOOL;           // команда работы ПЛК: Auto/Manual и eState = Starting или Running
    xEnteredStarting : BOOL;           // TRUE в вызове, в котором eState стало Starting
    // --- реализация (имена без «Vfd»: зарезервированы за наследником, L2) ---
    fbStartSup       : FB_Delay;       // tFbStart: нет ОС при пуске
    fbLossSup        : FB_Delay;       // tFbLossFilter: ОС пропала в работе
    fbStopSup        : FB_Delay;       // tFbStop: ОС не пропала при останове
    fbUncmdSup       : FB_Delay;       // tFbStart: ОС без команды ПЛК
    fbExtSup         : FB_Delay;       // tExtFaultFilter: внешняя авария
    fbStarts         : FB_StartsWindow;   // пуски за скользящий час
    xManualRun       : BOOL;           // ручная защёлка «работать» (Manual)
    xFltFailToStart  : BOOL;           // зафиксировано: нет ОС за tFbStart
    xFltFbLost       : BOOL;           // зафиксировано: ОС пропала в работе
    xFltFailToStop   : BOOL;           // зафиксировано: ОС не пропала за tFbStop
    xFltUncmd        : BOOL;           // зафиксировано: самопроизвольный пуск
    xFltExt          : BOOL;           // зафиксировано: внешняя авария
    xIlkTrip         : BOOL;           // остановлен блокировкой в работе (слот 5), пока блокировка действует
    wIlkPrev         : WORD;           // действующие блокировки прошлого вызова (для первопричины)
    uiFirstOut       : UINT := GVL_Const.NO_FIRST_OUT;   // номер бита первой блокировки; NO_FIRST_OUT — нет
    ltStopMark       : LTIME;          // момент останова: от него отсчитывается tMinStop
    ltRunEntry       : LTIME;          // вход в Running: от него отсчитывается tMinRun
    xAdoptPending    : BOOL := TRUE;   // подхват после старта ПЛК ещё не решён: нет достоверной ОС
    xFbStale         : BOOL;           // ОС недостоверна, и двигатель считается остановленным (VFD-11)
    xFbStaleRun      : BOOL;           // ОС устарела у работающего двигателя, пуска ПЛК с тех пор не было
    xRunOrCmdPrev    : BOOL;           // в прошлом вызове была команда работы или работа по ОС
    xRunCountPrev    : BOOL;           // работа для счётчиков прошлого вызова (фронт — пуск, наработка за шаг)
    xPowerPrev       : BOOL := TRUE;   // xPowerOk прошлого вызова (спад — останов для tMinStop)
    xResetWindow     : BOOL;           // идёт окно tResetWindow после Reset
    ltResetMark      : LTIME;          // момент последнего Reset
    ltRunAcc         : LTIME;          // накопитель наработки: доля секунды, не перенесённая в retain
    udiRunCurrent_s  : UDINT;          // текущая непрерывная работа, с
    udiRunSecondsMem : UDINT;          // stRetain.udiOpTime_s последнего вызова (RunSeconds)
    udiStartsMem     : UDINT;          // stRetain.udiOpCount последнего вызова (Starts)
    xReadyToStart    : BOOL;           // ReadyToStart последнего вызова
    xPresetReq       : BOOL;           // запрос PresetCounters()
    udiPresetTime_s  : UDINT;          // значение наработки запроса PresetCounters(), с
    udiPresetCount   : UDINT;          // значение числа пусков запроса PresetCounters()
END_VAR
VAR_TEMP
    xResetNow     : BOOL;              // Reset в этом вызове
    eRes          : E_CmdResult;       // результат ProcessMode
    xRemote       : BOOL;              // режим Auto или Manual
    xFbNow        : BOOL;              // ОС этого вызова (xFbRun или точка расширения)
    xFbOn         : BOOL;              // ОС достоверна и подтверждает работу
    xFbOff        : BOOL;              // ОС достоверна и подтверждает останов (без ОС — всегда)
    wIlkAct       : WORD;              // действующие блокировки: wInterlock AND wInterlockMask
    xIlk          : BOOL;              // блокировка действует
    wScan         : WORD;              // поиск младшего бита блокировок
    uiBit         : UINT;              // номер младшего бита
    wPermMiss     : WORD;              // недостающие разрешения: wPermitMask AND NOT wPermit
    xPermitOk     : BOOL;              // все разрешения есть и нет xStartBlockAdd
    xFaultAny     : BOOL;              // есть отказ (зафиксированный или связи)
    ltElapsed     : LTIME;             // прошло с отметки
    ltMinStop     : LTIME;             // tMinStop в LTIME
    ltMinStopLeft : LTIME;             // остаток паузы после останова
    ltFree        : LTIME;             // через сколько освободится окно пусков
    uiStartsHour  : UINT;              // пусков за скользящий час
    xStartsLimit  : BOOL;              // лимит пусков в час исчерпан
    xInhibit      : BOOL;              // запрет пуска: питание, пауза, лимит пусков
    xStartOk      : BOOL;              // все условия пуска 13.5 выполнены
    xAdoptNow     : BOOL;              // в этом вызове решается подхват после старта ПЛК
    xFbAssumedOff : BOOL;              // ОС недостоверна и нет питания или подтверждён отказ связи: «не работает»
    xFbRegain     : BOOL;              // ОС снова достоверна после xFbStale: решение — как при выходе из отказа
    xRunReq       : BOOL;              // запрос работы по режиму
    xForceStop    : BOOL;              // принудительный останов без tMinRun: нет Cfg, блокировка
    xSupervise    : BOOL;              // контроль ОС действует
    xMaintTime    : BOOL;              // ТО по наработке
    xMaintCount   : BOOL;              // ТО по числу пусков
    uliOneSecond   : ULINT;             // 1 с в нс (LTIME_TO_ULINT(LTIME#1S))
    udiWhole      : UDINT;             // целые секунды из накопителя
    uliRemain      : ULINT;             // остаток запрета пуска, нс
    xIdle         : BOOL;              // нет ни команды работы, ни работы по ОС
    xRunCount     : BOOL;              // работа для счётчиков: xRunning, провал ОС в Running внутри tFbLossFilter
    wLow          : WORD;              // младший байт wStatus
    wFlt          : WORD;              // wFault
    wWrn          : WORD;              // wWarning
    eDevSt        : E_Ne107Status;     // вклад логики двигателя в NE 107
    xAvailDev     : BOOL;              // готовность по логике двигателя
END_VAR
