// Назначение: сводка тревог всех источников PL.I_AlarmSource (устройства перечня, LIC101, станция): каждый
//             цикл — активные и неквитированные по приоритетам Low…Critical, высший неквитированный приоритет
//             (баннер) и счётчик новых неквитированных High/Critical (сирена); раз в ALM_VIEW_PERIOD — список
//             тревог не в Normal для HMI и сценариев (неквитированные выше, затем активные квитированные по
//             приоритету, затем отложенные, подавленные и выведенные из работы; внутри группы — новые выше).
//             Квитирование и откладывание тревоги по номеру (AckById, ShelveById).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 9.3; docs/04_algorithms.md, раздел 15
FUNCTION_BLOCK FB_AlarmSummary
VAR_INPUT
    aitfSource    : ARRAY[1..GVL_Const.ALM_SOURCE_MAX] OF PL.I_AlarmSource;   // источники; 0 — пропуск
    uiSourceCount : UINT;           // используемых источников, 0…ALM_SOURCE_MAX
    itfTime       : PL.I_TimeSource;    // GVL_Time.fbClockMain; 0 — LTIME()
END_VAR
VAR_OUTPUT
    auiActive     : ARRAY[1..GVL_Const.ALM_PRIO_COUNT] OF UINT;   // ActiveUnack и ActiveAck по приоритетам
    auiUnack      : ARRAY[1..GVL_Const.ALM_PRIO_COUNT] OF UINT;   // ActiveUnack и RtnUnack по приоритетам
    ePrioUnack    : PL.E_AlarmPriority;   // высший неквитированный приоритет; None — нет
    udiNewHighSeq : UDINT;          // +1 на каждый переход High/Critical в ActiveUnack
END_VAR
VAR_IN_OUT
    stView : ST_AlarmView;          // GVL_Log.stAlarmView, пересчёт раз в ALM_VIEW_PERIOD
END_VAR
VAR
    aeStatePrev : ARRAY[1..GVL_Const.ALM_SOURCE_MAX, 0..GVL_Const.ALM_SRC_SLOT_MAX] OF PL.E_AlarmState;
    audiSeqPrev : ARRAY[1..GVL_Const.ALM_SOURCE_MAX, 0..GVL_Const.ALM_SRC_SLOT_MAX] OF UDINT;
    auliSince   : ARRAY[1..GVL_Const.ALM_SOURCE_MAX, 0..GVL_Const.ALM_SRC_SLOT_MAX] OF ULINT;   // UTC перехода
    alrSince    : ARRAY[1..GVL_Const.ALM_SOURCE_MAX, 0..GVL_Const.ALM_SRC_SLOT_MAX] OF LREAL;   // время процесса
    fbSysTime   : PL.FB_SystemTime; // источник времени без itfTime
    itfTimeAct  : PL.I_TimeSource;  // действующий источник времени
    ltNow       : LTIME;            // время этого вызова
    ltViewLast  : LTIME;            // время последнего пересчёта списка
    xViewInit   : BOOL;             // список уже считался
    uiSrc       : UINT;             // источник
    uiK         : UINT;             // номер слота, с 1
    uiSlot      : UINT;             // слот
    uiPrio      : UINT;             // индекс приоритета 1…ALM_PRIO_COUNT
    itfSrc      : PL.I_AlarmSource; // источник
    itfAlm      : PL.I_Alarm;       // тревога слота
    eState      : PL.E_AlarmState;  // её состояние
    ePrio       : PL.E_AlarmPriority;   // её приоритет
    udiSeq      : UDINT;            // её счётчик переходов
END_VAR
