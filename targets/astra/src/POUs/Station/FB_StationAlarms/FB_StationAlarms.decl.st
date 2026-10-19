// Назначение: тревоги станции KNS1.* (04 §15, 05_alarm_list.csv) — 13 экземпляров PL.FB_Alarm,
//             индекс = E_StationAlarm, номер = STN_ALARM_ID_BASE + slot. Условия, подавления по
//             условию и значения задаёт PRG_Station; маски команд — бит slot - 1. Источник тревог
//             PL.I_AlarmSource для сводки (GetAlarm: индекс 0 — slot 1).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.11; docs/04_algorithms.md, раздел 15
FUNCTION_BLOCK FB_StationAlarms IMPLEMENTS PL.I_AlarmSource
VAR_INPUT
    axCond       : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF BOOL;   // индекс — E_StationAlarm
    axSuppress   : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF BOOL;   // SuppressedByDesign
    arValue      : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF REAL;
    wAckReq      : WORD;            // маски stStationCmd, бит slot - 1
    wShelveReq   : WORD;
    wUnshelveReq : WORD;
    xAckAll      : BOOL;
    itfTime      : PL.I_TimeSource;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // astAlarm[1..13]
END_VAR
VAR_OUTPUT
    wAlmActive  : WORD;
    wAlmUnack   : WORD;
    wAlmShelved : WORD;
    ePrioUnack  : PL.E_AlarmPriority;
END_VAR
VAR
    afbAlarm : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF PL.FB_Alarm;   // udiId = STN_ALARM_ID_BASE + slot
END_VAR
VAR_TEMP
    uiSlot : UINT;                  // слот тревоги
    wBit   : WORD;                  // бит слота в словах: slot - 1
    eState : PL.E_AlarmState;       // состояние тревоги после вызова
END_VAR
