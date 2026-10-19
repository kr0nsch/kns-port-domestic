// Назначение: АВР насосов (04 §9): отказ насоса, у которого был запрос в прошлом цикле (Fault —
//             нет ОС пуска, авария ПЧ, пропадание ОС; или блокировка станции насоса axTrip —
//             недогрузка, перегрев), — насос снят АВР до возврата доступности (KNS1.ATS),
//             событие 101006 с номером насоса, получившего новый запрос в окне STN_ATS_WINDOW.
//             Смена режима оператором, пропадание напряжения и сухой ход станции — не АВР. Условия
//             «недостаточно насосов» (KNS1.LACK) и «нет резерва» (KNS1.NORES); их задержки — в Cfg
//             тревог, подавления — в ядре станции (FB_StationCore).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.6; docs/04_algorithms.md, раздел 9
FUNCTION_BLOCK FB_Ats
VAR_INPUT
    xEnable     : BOOL;             // станция в «Автомате»
    aitfPump    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF PL.I_MotorVfd;
    axRun       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // запросы этого цикла (FB_PumpRotation)
    axTrip      : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // блокировка станции насоса: недогрузка, перегрев
    uiRequired  : UINT;
    uiAvailable : UINT;
    uiForeign   : UINT;
    itfTime     : PL.I_TimeSource;
    itfEvents   : I_StationEventSink;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // uiDutyMax
END_VAR
VAR_OUTPUT
    xAtsActive  : BOOL;             // есть насос, снятый АВР и ещё недоступный (KNS1.ATS)
    axRemoved   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;
    xLack       : BOOL;             // uiRequired > uiAvailable + uiForeign (KNS1.LACK; задержка — в Cfg тревоги)
    xNoReserve  : BOOL;             // uiAvailable < MIN(uiDutyMax, STN_DUTY_MAX) + 1 (KNS1.NORES; подавления — в ядре)
    udiAtsCount : UDINT;            // АВР с запуска (HMI)
END_VAR
VAR
    axRunPrev  : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;    // запросы прошлого цикла
    xWindow    : BOOL;              // идёт окно поиска замены (событие 101006)
    axReqAtAts : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;    // запросы в момент АВР: замена — новый запрос
    fbWindow   : PL.FB_Delay;       // окно STN_ATS_WINDOW
END_VAR
VAR_TEMP
    uiPump    : UINT;               // номер насоса
    xFailed   : BOOL;               // насос с запросом отказал в этом цикле
    xAvail    : BOOL;               // насос доступен
    xFault    : BOOL;               // отказ насоса (Fault) или фиксация станции (axTrip)
    uiNewPump : UINT;               // насос, получивший новый запрос в окне
END_VAR
