// Назначение: регулирующий клапан с позиционером 4–20 мА. Задание положения с пределами и
//             ограничением скорости (рампа, не зависящая от цикла), плотное закрытие, инверсия
//             выхода; контроль рассогласования с ОС положения (предупреждение или фиксируемый
//             отказ по конфигурации), отказ ОС, отказ позиционера; положение безопасности по
//             блокировке и отказу мимо рампы; выход xAutoActive для слежения ПИД. Режимы Auto,
//             Manual, Local (позиционер на месте — выход следит за ОС), OutOfService (удержание).
//             Наследует FB_DeviceBase: тело — нормативный порядок цикла (раздел 9.4 контракта).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_ControlValve.md
FUNCTION_BLOCK FB_ControlValve EXTENDS FB_DeviceBase
VAR_INPUT
    rPosSpAuto_pct   : REAL;             // задание от автоматики (ПИД), % хода
    rPosFb_pct       : REAL;             // ОС положения, % (обычно fbZT.rValue_pct)
    xPosFbValid      : BOOL;             // ОС достоверна (обычно fbZT.xValid)
    xLocal           : BOOL;             // позиционер в местном/ручном (байпас, маховик)
    wInterlock       : WORD := 16#0000;  // блокировки: бит = 1 — в rSafePos_pct
    xPositionerFault : BOOL;             // авария позиционера (DI) или отказ канала AO (диагностика модуля)
END_VAR
VAR_IN_OUT
    stCmd    : ST_ControlValveCmd;       // команды HMI/SCADA (GVL_Hmi.st<TAG>Cmd)
    stRetain : ST_DeviceRetain;          // режим, OOS (GVL_Persist.st<TAG>Retain)
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_ControlValveCfg;          // параметры (GVL_Persist.st<TAG>Cfg)
END_VAR
VAR_OUTPUT
    rOut_pct    : REAL;                  // задание положения, % хода (до инверсии)
    rOut_mA     : REAL := 4.0;           // на AO с учётом инверсии, мА
    xAutoActive : BOOL;                  // клапан следует rPosSpAuto_pct — ПИД: xTrack := NOT xAutoActive
    stSts       : ST_ControlValveSts;    // состояние для HMI/SCADA
END_VAR
VAR
    stCfgLkg     : ST_ControlValveCfg;   // последняя корректная конфигурация (LKG, нормативно)
    lrRamp_pct   : LREAL;                // положение до плотного закрытия — состояние рампы, % (LREAL, CV-14)
    xTightAct    : BOOL;                 // плотное закрытие действует (с гистерезисом CV_TIGHT_HYST_PCT, CV-13)
    xRampingPrev : BOOL;                 // в прошлом вызове рампа была активна
    xDevLatched  : BOOL;                 // зафиксированный отказ рассогласования (xDevIsFault)
    wIlkPrev     : WORD;                 // блокировки после маски в прошлом вызове (первопричина)
    uiFirstOut   : UINT := GVL_Const.NO_FIRST_OUT;   // номер бита первой блокировки; NO_FIRST_OUT — нет
    fbDev        : FB_Delay;             // задержка рассогласования tDev
    // --- сигналы и условия этого вызова: считает тело, читает шаг SelectOutput ---
    lrDt_s       : LREAL;                // шаг времени, с
    xRemote      : BOOL;                 // режим Auto или Manual
    wIlk         : WORD;                 // блокировки после маски
    xIlkAct      : BOOL;                 // блокировка действует (Auto/Manual)
    xFbOk        : BOOL;                 // ОС подключена, достоверна и конечна
    xFaultAny    : BOOL;                 // есть отказ (wFault <> 0)
    // --- результат выбора выхода этого вызова (пишет SelectOutput) ---
    rSpAct       : REAL;                 // задание после пределов, до рампы, %
    xSafe        : BOOL;                 // выход принудительно в положение безопасности
    xRamping     : BOOL;                 // рампа не дошла до задания
    xLimMin      : BOOL;                 // задание ограничено снизу
    xLimMax      : BOOL;                 // задание ограничено сверху
    xSpInvalid   : BOOL;                 // задание не конечно, выход удерживается
END_VAR
VAR_TEMP
    xResetNow  : BOOL;                   // Reset в этом вызове
    eRes       : E_CmdResult;            // результат ProcessMode
    wBit       : WORD;                   // бит при поиске первопричины
    uiBit      : UINT;                   // номер бита при поиске первопричины
    xFbInvalid : BOOL;                   // ОС подключена, но недостоверна
    xPosFault  : BOOL;                   // отказ позиционера (не в OutOfService)
    xDevCond   : BOOL;                   // условие рассогласования до задержки
    xDevWarn   : BOOL;                   // рассогласование — предупреждение
    xManualCtl : BOOL;                   // выходом управляет оператор (Manual без блокировки и отказа)
    rTightOff  : REAL;                   // положение снятия плотного закрытия, %
    xInvert    : BOOL;                   // инверсия выхода мА
    wFltBits   : WORD;                   // wFault
    wWrnBits   : WORD;                   // wWarning
    wLowBits   : WORD;                   // младший байт wStatus
    eDevSt     : E_Ne107Status;          // вклад устройства в NE 107
    xAvailDev  : BOOL;                   // готовность для автоматики (без учёта Cfg)
    xAtSp      : BOOL;                   // |выход - ОС| <= rDevMax_pct
END_VAR
