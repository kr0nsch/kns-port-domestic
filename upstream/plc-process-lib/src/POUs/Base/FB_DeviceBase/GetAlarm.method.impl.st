IF uiIndex < MIN(uiAlarmCount, GVL_Const.DEV_ALARMS_MAX) THEN
    GetAlarm := afbAlarm[uiIndex];
ELSE
    GetAlarm := 0;
END_IF
