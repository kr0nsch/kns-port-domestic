// PL.I_AlarmSink: переход тревоги (PL.FB_Alarm устройств, станции, LIC101) — запись вида Alarm; всегда TRUE
METHOD OnAlarmEvent : BOOL
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stEvent : PL.ST_AlarmEvent;     // событие
END_VAR
