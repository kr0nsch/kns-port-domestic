SUPER^.OnModeChanged(eOld := eOld, eNew := eNew);
IF eOld = E_DeviceMode.Auto AND eNew = E_DeviceMode.Manual THEN
    xManualRun := xRunCmd;
ELSIF (eOld = E_DeviceMode.Local OR eOld = E_DeviceMode.OutOfService)
      AND (eNew = E_DeviceMode.Auto OR eNew = E_DeviceMode.Manual)
THEN
    xManualRun := xRunning;
END_IF
IF eNew = E_DeviceMode.OutOfService THEN
    xFltFailToStart := FALSE;
    xFltFbLost := FALSE;
    xFltFailToStop := FALSE;
    xFltUncmd := FALSE;
    xFltExt := FALSE;
    xResetWindow := FALSE;
    uiFirstOut := GVL_Const.NO_FIRST_OUT;
END_IF
