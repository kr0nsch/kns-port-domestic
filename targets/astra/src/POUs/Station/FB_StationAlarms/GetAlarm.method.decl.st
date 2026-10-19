// Тревога по индексу источника: 0 — slot 1 (EHL) … STN_ALARM_COUNT - 1 — slot 13 (SIM); вне — 0
METHOD PUBLIC GetAlarm : PL.I_Alarm
VAR_INPUT
    uiIndex : UINT;                 // индекс 0…AlarmCount - 1
END_VAR
