AckAll := FALSE;
FOR uiIdx := 1 TO GVL_Const.STN_ALARM_COUNT DO
    IF afbAlarm[uiIdx].Ack() THEN
        AckAll := TRUE;
    END_IF
END_FOR
