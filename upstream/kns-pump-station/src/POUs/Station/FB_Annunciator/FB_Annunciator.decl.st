// Назначение: местная сигнализация (04 §14): сирена HA1 — новая неквитированная тревога High или
//             Critical, выключается кнопкой HS502, командой «Звук» или квитированием, новая
//             тревога включает снова; лампа HL1 — мигает 1 Гц при неквитированных Medium и выше,
//             горит при активных квитированных; реле K1 «Общая авария» — под напряжением в норме,
//             обесточено при активной High или Critical (принцип «отказ — сигнал»).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.12; docs/04_algorithms.md, раздел 14
FUNCTION_BLOCK FB_Annunciator
VAR_INPUT
    auiUnack      : ARRAY[1..GVL_Const.ALM_PRIO_COUNT] OF UINT;   // Low…Critical (FB_AlarmSummary)
    auiActive     : ARRAY[1..GVL_Const.ALM_PRIO_COUNT] OF UINT;
    udiNewHighSeq : UDINT;          // растёт на каждую новую неквитированную High/Critical
    xSilence      : BOOL;           // импульс: фронт HS502 OR stStationCmd.xSilence
    itfTime       : PL.I_TimeSource;
END_VAR
VAR_OUTPUT
    xHorn        : BOOL;            // → GVL_IO.xHA1
    xLamp        : BOOL;            // → GVL_IO.xHL1: мигает 1 Гц при неквитированных Medium+, горит при активных
    xK1Energized : BOOL;            // → GVL_IO.xK1: TRUE — норма, FALSE — активна High/Critical
END_VAR
VAR
    udiSeqPrev   : UDINT;           // udiNewHighSeq прошлого вызова
    xFirstCall   : BOOL := TRUE;    // первый вызов: счётчик сводки принимается как есть
    xBlinking    : BOOL;            // лампа в режиме мигания (прошлый вызов)
    ltBlinkStart : LTIME;           // начало мигания: фаза «горит»
    fbSysTime    : PL.FB_SystemTime;    // запасной источник времени (itfTime = 0)
END_VAR
VAR_TEMP
    uiPrio      : UINT;             // индекс приоритета
    uiUnackMed  : UINT;             // неквитированных Medium и выше
    uiUnackHigh : UINT;             // неквитированных High и выше
    uiActMed    : UINT;             // активных Medium и выше
    uiActHigh   : UINT;             // активных High и выше
    ltNow       : LTIME;            // время этого вызова
    uliHalf     : ULINT;            // полупериод мигания, нс
END_VAR
