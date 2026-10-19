SUPER^.OnModeChanged(eOld := eOld, eNew := eNew);
IF eOld = E_DeviceMode.OutOfService THEN
    xCalcInit := TRUE;
END_IF
IF eNew = E_DeviceMode.Auto THEN
    lrI_pct := lrOut_pct - lrP_pct - lrD_pct;
END_IF
