F_AlarmCode := UDINT_TO_STRING(udiId);
IF udiId >= GVL_Const.STN_EVENT_ID_BASE THEN
    // событие станции: KNS1.E<код>
    F_AlarmCode := CONCAT(CONCAT(STATION_TAG, '.'),
                          CONCAT(EVENT_PREFIX, UDINT_TO_STRING(udiId - GVL_Const.STN_EVENT_ID_BASE)));
ELSIF udiId >= GVL_Const.LIC101_ALARM_ID_BASE
      AND udiId <= GVL_Const.LIC101_ALARM_ID_BASE + GVL_Const.ALM_SLOT_MAX THEN
    sSuffix := PID_SUFFIX[UDINT_TO_UINT(udiId - GVL_Const.LIC101_ALARM_ID_BASE)];
    IF LEN(sSuffix) > 0 THEN
        F_AlarmCode := CONCAT(CONCAT(PID_TAG, '.'), sSuffix);
    END_IF
ELSIF udiId > GVL_Const.STN_ALARM_ID_BASE AND udiId <= GVL_Const.STN_ALARM_ID_BASE + GVL_Const.STN_ALARM_COUNT THEN
    F_AlarmCode := CONCAT(CONCAT(STATION_TAG, '.'), STN_SUFFIX[UDINT_TO_UINT(udiId - GVL_Const.STN_ALARM_ID_BASE)]);
ELSIF udiId < GVL_Const.STN_ALARM_ID_BASE THEN
    // устройство перечня: dev_no · 10 + слот
    uiDevNo := UDINT_TO_UINT(udiId / ID_PER_DEVICE);
    uiSlot := UDINT_TO_UINT(udiId MOD ID_PER_DEVICE);
    IF uiSlot <= GVL_Const.ALM_SLOT_MAX THEN
        FOR uiI := 1 TO GVL_DeviceList.DEVICE_COUNT DO
            IF GVL_DeviceList.auiDevNo[uiI] = uiDevNo THEN
                eType := GVL_DeviceList.aeDevType[uiI];
                IF eType = PL.E_DeviceType.AnalogInput THEN
                    sSuffix := AI_SUFFIX[uiSlot];
                ELSIF eType = PL.E_DeviceType.DigitalInput THEN
                    sSuffix := DI_SUFFIX[uiSlot];
                ELSIF eType = PL.E_DeviceType.Motor OR eType = PL.E_DeviceType.MotorVfd THEN
                    sSuffix := MOT_SUFFIX[uiSlot];
                ELSIF eType = PL.E_DeviceType.Valve THEN
                    sSuffix := VLV_SUFFIX[uiSlot];
                ELSIF eType = PL.E_DeviceType.ControlValve THEN
                    sSuffix := CV_SUFFIX[uiSlot];
                ELSIF eType = PL.E_DeviceType.Pid THEN
                    sSuffix := PID_SUFFIX[uiSlot];
                ELSE
                    sSuffix := '';
                END_IF
                IF LEN(sSuffix) = 0 THEN
                    sSuffix := UINT_TO_STRING(uiSlot);   // слот без суффикса в контракте — номер слота
                END_IF
                F_AlarmCode := CONCAT(CONCAT(GVL_DeviceList.asTag[uiI], '.'), sSuffix);
                RETURN;
            END_IF
        END_FOR
    END_IF
END_IF
