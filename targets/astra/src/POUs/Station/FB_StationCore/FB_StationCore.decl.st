// Назначение: ядро PRG_Station — порядок цикла станции (DESIGN, раздел 7, шаги 2–15) без обращений
//             к глобальным переменным: уставки (LKG с энергонезависимой копией, «Применить уставки
//             проекта», откат), команды станции и кнопки шкафа, режим, питание, защиты, действующее
//             управление, ступенчатое и ПИД (LIC101), чередование, АВР, задание частоты, блокировки,
//             вентиляция, тревоги KNS1.*, местная сигнализация, события журнала, состояние
//             stStationSts. Устройства — интерфейсами PL.I_MotorVfd и значениями входов, журнал —
//             I_StationEventSink, время — PL.I_TimeSource, данные GVL_Station и GVL_Persist —
//             параметрами VAR_IN_OUT: юнит-тесты идут с подменными насосами и временем, без модели и
//             сгенерированного слоя. Привязку к GVL_Devices, GVL_Hmi, GVL_IO, GVL_Persist, GVL_Log,
//             GVL_Sim, GVL_Time и GVL_DeviceList выполняет PRG_Station.
// Автор:      kr0nsch
// Версия:     0.2.0
// Документ:   docs/DESIGN.md, разделы 6.15 и 7; docs/04_algorithms.md, разделы 4, 15, 16, 18.3, 19
FUNCTION_BLOCK FB_StationCore
VAR_INPUT
    itfTime           : PL.I_TimeSource;      // GVL_Time.fbClockMain
    itfEvents         : I_StationEventSink;   // GVL_Log.fbEventLog
    aitfPump          : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF PL.I_MotorVfd;   // GVL_Devices.fbP101…fbP103
    axCommOk          : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // нет MOT_WRN_COMM_LOSS в wWarning насоса
    axRunFeedback     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // GVL_IO.xP10n_RFB: подхват при старте ПЛК
    axPumpReset       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // GVL_Hmi.stP10nCmd.stCommon.xReset
    arCurrent_A       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // fbIT1n1.rValue_eu
    axCurrentValid    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // fbIT1n1.xValid
    axOverheat        : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // fbTS1n2.xValue
    rLevel_m          : REAL;                 // fbLT101.rValue_eu
    xLevelValid       : BOOL;                 // fbLT101.xValid
    eLevelNe107       : PL.E_Ne107Status;     // fbLT101.stSts.stCommon.eNe107
    xLevelL           : BOOL;                 // fbLT101.xL, xLL, xH, xHH
    xLevelLL          : BOOL;
    xLevelH           : BOOL;
    xLevelHH          : BOOL;
    rLvlL_m           : REAL;                 // GVL_Persist.stLT101Cfg: уставка L (порядок отметок)
    rLvlH_m           : REAL;                 // уставка H
    xFloatHigh        : BOOL;                 // fbLS102.xValue
    xFloatDry         : BOOL;                 // fbLS103.xValue
    xPowerOk          : BOOL;                 // fbES301.xValue
    xResetButton      : BOOL;                 // fbHS501.xValue (фронт выделяет ФБ)
    xSilenceButton    : BOOL;                 // fbHS502.xValue
    xGasHigh          : BOOL;                 // fbAT401.xH OR fbAT402.xH
    xDoorOpen         : BOOL;                 // fbZS404.xValue
    xTempHigh         : BOOL;                 // fbTT403.xH
    xFire             : BOOL;                 // fbYS405.xValue
    xApplyProjectCfg  : BOOL;                 // GVL_Hmi.xApplyProjectCfg (импульс сбрасывает PRG_Devices)
    xAckIdFound       : BOOL;                 // GVL_Log.fbAlarmSummary.AckById(stCmd.udiAckId) этого цикла
    xShelveIdFound    : BOOL;                 // … ShelveById(stCmd.udiShelveId, TRUE)
    xUnshelveIdFound  : BOOL;                 // … ShelveById(stCmd.udiUnshelveId, FALSE)
    xSimulation       : BOOL;                 // GVL_Sim.xSimulation
    udiSimFaultSeq    : UDINT;                // GVL_Sim.stSimSts.udiFaultSeq
    eLogExport        : E_LogExportState;     // GVL_Log.eExportState
    uiExportLines     : UINT;                 // GVL_Log.uiExportLines
    udiExportError    : UDINT;                // GVL_Log.udiExportError
    udiEventSeq       : UDINT;                // GVL_Log.fbEventLog.udiSeqLast
    udiLogOverwritten : UDINT;                // GVL_Log.fbEventLog.udiOverwritten
    auiUnack          : ARRAY[1..GVL_Const.ALM_PRIO_COUNT] OF UINT;   // GVL_Log.fbAlarmSummary (прошлый цикл)
    auiActive         : ARRAY[1..GVL_Const.ALM_PRIO_COUNT] OF UINT;
    ePrioUnack        : PL.E_AlarmPriority;
    udiNewHighSeq     : UDINT;
END_VAR
VAR_IN_OUT
    stCmd          : ST_StationCmd;           // GVL_Station.stStationCmd: импульсы и номера сбрасываются
    stCfgPersist   : ST_StationCfg;           // GVL_Persist.stStationCfg
    stCfgLkg       : ST_StationCfg;           // GVL_Station.stCfgLkg
    stCfgLkgRetain : ST_StationCfg;           // GVL_Persist.stStationCfgLkg: копия LKG, переживает перезапуск
    stRetain       : ST_StationRetain;        // GVL_Persist.stStationRetain
    fbLIC101       : PL.FB_PID;               // GVL_Station.fbLIC101
    stLIC101Cmd    : PL.ST_PidCmd;            // GVL_Station.stLIC101Cmd
    stLIC101Cfg    : PL.ST_PidCfg;            // GVL_Persist.stLIC101Cfg
    stLIC101Retain : PL.ST_DeviceRetain;      // GVL_Persist.stLIC101Retain
    fbAlarms       : FB_StationAlarms;        // GVL_Station.fbAlarms
END_VAR
VAR_OUTPUT
    stSts               : ST_StationSts;      // → GVL_Station.stStationSts
    axRun               : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // → fbP10n.xAutoRun, GVL_Station.axPumpRun
    awInterlock         : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF WORD;   // → fbP10n.wInterlock, awPumpInterlock
    rSpeedSp_pct        : REAL;               // → fbP10n.rSpeedSpAuto_pct, GVL_Station.rSpeedSp_pct
    xSuppressFlowAlarms : BOOL;               // → fbPT201, fbFT202.xSuppressLimitAlarms
    xV1Run              : BOOL;               // → fbV1.xAutoRun
    wV1Interlock        : WORD;               // → fbV1.wInterlock
    xHorn               : BOOL;               // → GVL_IO.xHA1
    xLamp               : BOOL;               // → GVL_IO.xHL1
    xK1                 : BOOL;               // → GVL_IO.xK1 (TRUE — норма)
    xResetAllReq        : BOOL;               // импульс: Reset() всех GVL_DeviceList.aitfDevice
    xAckAllReq          : BOOL;               // импульс: AckAll() всех GVL_DeviceList.aitfDevice
    xExportReq          : BOOL;               // импульс: GVL_Log.fbEventLog.TakeSnapshot(), GVL_Log.xExportReq := TRUE
END_VAR
VAR
    fbMode         : FB_StationMode;          // 6.1
    fbPower        : FB_PowerRestore;         // 6.9
    fbProt         : FB_Protections;          // 6.7
    afbPumpProt    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF FB_PumpProtection;   // 6.8
    fbSelect       : FB_ControlSelector;      // 6.2
    fbStepped      : FB_LevelControlStepped;  // 6.3
    fbPidCtl       : FB_LevelControlPid;      // 6.4
    fbRotation     : FB_PumpRotation;         // 6.5
    fbAts          : FB_Ats;                  // 6.6
    fbVent         : FB_Ventilation;          // 6.10
    fbAnnunciator  : FB_Annunciator;          // 6.12
    fbFlowSettle   : PL.FB_Delay;             // насос работает дольше STN_FLOW_SETTLE: давление и расход набраны
    xFirstCall     : BOOL := TRUE;            // первый вызов: старт приложения
    xResetBtnPrev  : BOOL;                    // HS501 прошлого вызова (фронт)
    xSilenceBtnPrev : BOOL;                   // HS502 прошлого вызова (фронт)
    uiRequiredPrev : UINT;                    // требуемое число прошлого цикла (FB_PowerRestore)
    eLogExportPrev : E_LogExportState;        // состояние выгрузки прошлого вызова (события 101019/101020)
    udiSimSeqPrev  : UDINT;                   // счётчик инъекций прошлого вызова (событие 101021)
    wCfgErr        : WORD;                    // ошибки уставок этого вызова
    eActPrev       : E_ControlAct;            // действующее управление прошлого вызова
END_VAR
VAR_TEMP
    uiPump         : UINT;                    // номер насоса
    uiCmdCount     : UINT;                    // обработано команд станции в этом вызове
    eCmdRes        : PL.E_CmdResult;          // результат последней команды
    xResetNow      : BOOL;                    // общий сброс в этом вызове (HS501 или HMI)
    xAckNow        : BOOL;                    // квитировать все (HMI)
    xSilenceNow    : BOOL;                    // «Звук» (HS502 или HMI)
    xCfgCmd        : BOOL;                    // уставки переписаны командой (событие уже записано)
    uiParam        : UINT;                    // номер изменённого параметра (событие 101017)
    wAckMask       : WORD;                    // маски команд тревог станции этого вызова
    wShelveMask    : WORD;
    wUnshelveMask  : WORD;
    uiRunningNow   : UINT;                    // работающие насосы
    axAdoptRun     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // «работает» для подхвата
    axTrip         : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // фиксация недогрузки (KNS1.ULn)
    axAtsTrip      : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // блокировка станции насоса (АВР)
    xAnyRunning    : BOOL;                    // работает хотя бы один насос
    xInitReq       : BOOL;                    // вход без рывка: смена управления или вход в «Автомат»
    xSteppedCont   : BOOL;                    // ступенчатый автомат продолжает работу (Restart <-> Stepped)
    eAct           : E_ControlAct;            // действующее управление
    uiRequired     : UINT;                    // требуемое число насосов
    uiTrack        : UINT;                    // «Ручной»: работающий насос с меньшей наработкой
    axCond         : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF BOOL;  // условия тревог KNS1.*
    axSuppress     : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF BOOL;  // подавления по условию
    arValue        : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF REAL;  // значения для событий
    uiSlot         : UINT;                    // слот тревоги
    xManual        : BOOL;                    // станция в «Ручном»
    eNe107         : PL.E_Ne107Status;        // сводный статус
    wState         : WORD;                    // биты STN_ST_*
    xMaint         : BOOL;                    // насосу нужно ТО
END_VAR
