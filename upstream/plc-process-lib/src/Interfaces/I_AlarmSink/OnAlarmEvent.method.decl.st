// Событие перехода тревоги; FALSE — приёмник переполнен (FB_Alarm результат не повторяет)
METHOD OnAlarmEvent : BOOL
VAR_IN_OUT CONSTANT
    stEvent : ST_AlarmEvent;   // событие
END_VAR
