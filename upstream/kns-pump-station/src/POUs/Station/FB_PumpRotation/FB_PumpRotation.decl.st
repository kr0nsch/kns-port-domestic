// Назначение: роли насосов, чередование и ограничение непрерывной работы (04 §5, §8). Запросы
//             получают насосы с ролями Lead и Assist; роли работающих по запросу насосов
//             сохраняются; недостающая роль — сначала ReadyToStart, затем доступные в паузе,
//             внутри группы — по eRotation (RunHours, Cyclic, Fixed); в ПИД ведущим — насос со
//             связью с ПЧ. Новый запрос — не раньше tStagger после предыдущего (если тот ещё
//             запрошен). Снятие роли: RunHours — насос с большей наработкой, Cyclic/Fixed —
//             подпорный. Отказавший насос теряет запрос сразу. Передача роли с перекрытием
//             tOverlap после tMaxContRun (событие 101007), повтор через STN_HANDOVER_RETRY.
//             uiRequestLimit (последовательный пуск) ограничивает новые запросы: насосы, уже
//             работающие по запросу (подхват при старте ПЛК), им не снимаются.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.5; docs/04_algorithms.md, разделы 5, 8
FUNCTION_BLOCK FB_PumpRotation
VAR_INPUT
    xEnable          : BOOL;        // станция в «Автомате» (иначе запросов нет, роли считаются)
    uiRequired       : UINT;        // от действующего управления, 0…STN_PUMP_COUNT
    uiRequestLimit   : UINT;        // FB_PowerRestore: сколько запросов можно выдать
    xRequireComm     : BOOL;        // eControlAct = LevelPid: ведущий — только со связью
    xHandoverAllowed : BOOL;        // не Emergency, Float, Restart
    xAdopt           : BOOL;        // импульс: роли получают работающие насосы (вход в «Автомат», смена управления)
    axAdoptRun       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;  // «работает» для xAdopt (старт: GVL_IO.xP10n_RFB)
    aitfPump         : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF PL.I_MotorVfd;
    axCommOk         : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;
    itfTime          : PL.I_TimeSource;
    itfEvents        : I_StationEventSink;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // eRotation, uiDutyMax, tMaxContRun, tOverlap, tStagger
END_VAR
VAR_IN_OUT
    stRetain : ST_StationRetain;    // uiNextLead (Cyclic)
END_VAR
VAR_OUTPUT
    axRun              : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // → fbP10n.xAutoRun
    aeRole             : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF E_PumpRole;
    uiLead             : UINT;
    uiAvailable        : UINT;      // Available
    uiRunning          : UINT;      // Running в любом режиме
    uiForeign          : UINT;      // работают не в Auto (сторонние, 04 §5.1)
    uiRequests         : UINT;      // запросы: не больше MAX(0, uiRequired - uiForeign), новые — до uiRequestLimit
    uiRunningRequested : UINT;      // запрошены и работают по ОС (для FB_PowerRestore)
    xHandover          : BOOL;      // идёт передача роли (перекрытие)
    xStaggerWait       : BOOL;      // новый запрос ждёт tStagger
END_VAR
VAR
    // снимок насосов этого вызова (методы читают его, а не интерфейсы)
    axAvail       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;    // Available
    axRunning     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;    // Running
    axReady       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;    // ReadyToStart
    audiHours     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF UDINT;   // RunSeconds
    audiStarts    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF UDINT;   // Starts
    audiCurRun    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF UDINT;   // CurrentRunSeconds
    axForeign     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;    // работает не в Auto
    // запросы и роли
    axReq         : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;    // запрос (роль Lead или Assist)
    audiReqSeq    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF UDINT;   // порядок выдачи запросов (подпорный — последний)
    udiReqSeq     : UDINT;          // счётчик выданных запросов
    uiLeadIdx     : UINT;           // ведущий; 0 — нет
    uiLeadPrev    : UINT;           // ведущий прошлого вызова (событие 101005)
    // интервал пусков
    xStaggerArmed : BOOL;           // после нового запроса идёт отсчёт tStagger
    ltLastNewReq  : LTIME;          // время последнего нового запроса
    uiLastNewPump : UINT;           // насос последнего нового запроса
    // передача роли по ограничению непрерывной работы
    xHoActive     : BOOL;           // идёт передача
    uiHoOld       : UINT;           // насос, отработавший tMaxContRun
    uiHoNew       : UINT;           // насос-замена
    uiHoTarget    : UINT;           // требуемое число насосов в момент начала передачи
    xHoRetryWait  : BOOL;           // ожидание повтора STN_HANDOVER_RETRY
    fbHoStart     : PL.FB_Delay;    // замена не пустилась за STN_HANDOVER_START_TIMEOUT
    fbHoOverlap   : PL.FB_Delay;    // перекрытие tOverlap после пуска замены
    fbHoRetry     : PL.FB_Delay;    // повтор попытки через STN_HANDOVER_RETRY
    fbSysTime     : PL.FB_SystemTime;   // запасной источник времени (itfTime = 0)
END_VAR
VAR_TEMP
    uiPump        : UINT;           // номер насоса
    uiStep        : UINT;           // шаг цикла добавления и снятия запросов
    uiPick        : UINT;           // выбранный насос
    uiCount       : UINT;           // выданных запросов
    uiTarget      : UINT;           // нужно запросов: MAX(0, uiRequired - uiForeign)
    ltNow         : LTIME;          // время этого вызова
    ePumpMode     : PL.E_DeviceMode;    // режим насоса
    xStaggerOk    : BOOL;           // новый запрос разрешён по интервалу пусков
    xHoNewRunning : BOOL;           // замена работает по ОС
    udiMaxRun_s   : UDINT;          // tMaxContRun в секундах
END_VAR
