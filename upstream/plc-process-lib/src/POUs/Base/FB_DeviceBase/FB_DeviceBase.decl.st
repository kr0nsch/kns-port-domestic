// Назначение: абстрактная база устройств библиотеки (I_Device, I_AlarmSource): время цикла,
//             режимы (Auto, Manual, Local, OutOfService) с энергонезависимым дистанционным
//             режимом, конфигурация с последней корректной копией (LKG), результат команд,
//             восемь слотов FB_Alarm, сводный статус NAMUR NE 107 и общий заголовок Sts.
//             Тело пустое: порядок цикла задаёт наследник (docs/fb/FB_DeviceBase.md, «Порядок
//             тела»), шаги цикла — защищённые методы. Все переменные секции VAR — часть контракта
//             для наследников, их имена зарезервированы (повтор имени в наследнике — C0097).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_DeviceBase.md
FUNCTION_BLOCK ABSTRACT FB_DeviceBase IMPLEMENTS I_Device
VAR_INPUT
    itfTime : I_TimeSource;                  // источник времени; 0 — встроенный fbSysTime
END_VAR
VAR
    // --- время (BeginCycle) ---
    fbSysTime      : FB_SystemTime;          // запасной источник
    itfTimeAct     : I_TimeSource;           // действующий источник этого вызова
    ltNow          : LTIME;                  // время этого вызова
    ltPrevCall     : LTIME;                  // время предыдущего вызова
    ltDt           : LTIME;                  // ltNow - ltPrevCall; LTIME#0S в первом вызове и при «времени назад»
    xFirstCall     : BOOL := TRUE;           // TRUE до конца первого вызова (FinishCycle)
    // --- режим ---
    eMode          : E_DeviceMode := E_DeviceMode.Manual;   // текущий режим
    xModeReq       : BOOL;                   // есть запрос RequestMode() (снимает FinishCycle)
    eModeReq       : E_DeviceMode := E_DeviceMode.Manual;   // значение запроса; не INT: строгое перечисление (L4)
    stModeMem      : ST_DeviceRetain;        // память режима для ФБ без stRetain (AI, DI)
    xManualIsCheck : BOOL;                   // TRUE у AI/DI: Manual (подмена) даёт CheckFunction
    eDevType       : E_DeviceType := E_DeviceType.None;     // задаёт наследник; FinishCycle пишет в stCommon
    // --- конфигурация ---
    wCfgErr        : WORD;                   // результат CheckConfig этого вызова
    xCfgEverOk     : BOOL;                   // корректная Cfg была хотя бы раз (есть LKG)
    // --- статус ---
    eNe107         : E_Ne107Status := E_Ne107Status.CheckFunction;
    xFault         : BOOL;                   // eNe107 = Failure
    xAvailable     : BOOL;                   // можно рассчитывать на устройство в автомате
    // --- запросы методов ---
    xResetReq      : BOOL;                   // Reset()
    xAckAllReq     : BOOL;                   // AckAll()
    // --- результат команд ---
    eCmdResult     : E_CmdResult := E_CmdResult.None;
    uiCmdSeq       : UINT;                   // +1 на каждую обработанную команду (по кругу)
    // --- тревоги (слоты 0..DEV_ALARMS_MAX - 1) ---
    uiAlarmCount   : UINT;                   // используемых слотов; задаёт наследник в первом вызове
    afbAlarm       : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF FB_Alarm;   // слоты тревог
    axAlmCond      : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF BOOL;       // условия (заполняет наследник)
    axAlmSuppress  : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF BOOL;       // подавление по условию
    arAlmValue     : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF REAL;       // значение для события
    wAlmActive     : WORD;                   // бит i: условие слота i активно (после задержек)
    wAlmUnack      : WORD;                   // бит i: слот i не квитирован
    wAlmShelved    : WORD;                   // бит i: слот отложен оператором (Shelved)
    wAlmSuppressed : WORD;                   // бит i: слот подавлен логикой (SuppressedByDesign)
    ePrioUnack     : E_AlarmPriority := E_AlarmPriority.None;   // наивысший приоритет неквитированных
END_VAR
