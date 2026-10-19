FOR uiI := 1 TO GVL_DeviceList.DEVICE_COUNT DO
    itfDev := aitfDevice[uiI];
    IF itfDev <> 0 THEN
        eMode := itfDev.Mode;
        IF axKnown[uiI] AND eMode <> aeModePrev[uiI] THEN
            udiChanges := udiChanges + 1;
            IF itfEvents <> 0 THEN
                // в UDINT: dev_no до 9999 (API 20.1) · 10 не помещается в UINT
                itfEvents.LogEvent(eEvent := E_StationEvent.DeviceModeChanged,
                                   rValue := UDINT_TO_REAL(UINT_TO_UDINT(auiDevNo[uiI])
                                                           * UINT_TO_UDINT(GVL_Const.LOG_DEV_MODE_SCALE)
                                                           + TO_UDINT(eMode)));
            END_IF
        END_IF
        aeModePrev[uiI] := eMode;
        axKnown[uiI] := TRUE;
    END_IF
END_FOR
