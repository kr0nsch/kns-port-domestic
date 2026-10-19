IF uiIndex < GVL_Const.STN_ALARM_COUNT THEN
    GetAlarm := afbAlarm[uiIndex + 1];
ELSE
    GetAlarm := 0;
END_IF
