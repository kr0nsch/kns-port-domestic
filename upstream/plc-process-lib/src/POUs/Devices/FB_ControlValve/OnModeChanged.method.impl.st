SUPER^.OnModeChanged(eOld := eOld, eNew := eNew);
lrRamp_pct := REAL_TO_LREAL(rOut_pct);
IF eNew = E_DeviceMode.OutOfService THEN
    xDevLatched := FALSE;
    fbDev.Preset(xValue := FALSE);
    uiFirstOut := GVL_Const.NO_FIRST_OUT;
END_IF
