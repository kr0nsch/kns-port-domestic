IF eNew = E_DeviceMode.Auto OR eNew = E_DeviceMode.Manual THEN
    stRetain.eRemoteMode := eNew;
    IF (eMode = E_DeviceMode.Auto OR eMode = E_DeviceMode.Manual) AND eMode <> eNew THEN
        eModeOld := eMode;
        eMode := eNew;
        THIS^.OnModeChanged(eOld := eModeOld, eNew := eNew);
    END_IF
END_IF
