// PL.I_AlarmSink: переход тревоги (PL.FB_Alarm устройств, станции, LIC101) — запись вида Alarm; всегда TRUE
METHOD OnAlarmEvent : BOOL
VAR_IN_OUT CONSTANT
    stEvent : PL.ST_AlarmEvent;     // событие
END_VAR
