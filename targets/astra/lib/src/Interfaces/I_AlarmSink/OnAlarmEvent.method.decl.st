// Событие перехода тревоги; FALSE — приёмник переполнен (FB_Alarm результат не повторяет)
METHOD OnAlarmEvent : BOOL
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stEvent : ST_AlarmEvent;   // событие
END_VAR
