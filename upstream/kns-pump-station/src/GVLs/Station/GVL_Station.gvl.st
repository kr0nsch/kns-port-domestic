// Назначение: данные обмена станции с HMI, OPC UA и MQTT (04 §19.1). Команды пишут клиенты,
//             остальное пишет только PRG_Station.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 4.1
{attribute 'qualified_only'}
VAR_GLOBAL
    stStationCmd    : ST_StationCmd;     // команды (ReadWrite в символах)
    stStationSts    : ST_StationSts;     // состояние (Read)
    fbLIC101        : PL.FB_PID;         // регулятор уровня; HMI и SCADA читают fbLIC101.stSts
    stLIC101Cmd     : PL.ST_PidCmd;      // команды фейсплейта LIC101 (ReadWrite)
    fbAlarms        : FB_StationAlarms;  // тревоги KNS1.* (источник для сводки)
    // диагностика для HMI и OPC UA (пишет только PRG_Station)
    axPumpRun       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // → fbP10n.xAutoRun
    awPumpInterlock : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF WORD;   // → fbP10n.wInterlock
    rSpeedSp_pct    : REAL;                                         // → fbP10n.rSpeedSpAuto_pct
    stCfgLkg        : ST_StationCfg;     // последняя корректная копия уставок (Read)
END_VAR
