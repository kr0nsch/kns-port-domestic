IF eNewMode = E_DeviceMode.Auto OR eNewMode = E_DeviceMode.Manual OR eNewMode = E_DeviceMode.OutOfService THEN
    eModeReq := eNewMode;
    xModeReq := TRUE;
    RequestMode := TRUE;
ELSE
    RequestMode := FALSE;
END_IF
