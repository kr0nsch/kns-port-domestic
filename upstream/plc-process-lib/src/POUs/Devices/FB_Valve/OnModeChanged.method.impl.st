SUPER^.OnModeChanged(eOld := eOld, eNew := eNew);
IF eNew = E_DeviceMode.Manual THEN
    eManTarget := CurrentTarget();
END_IF
IF eNew = E_DeviceMode.OutOfService THEN
    xFltFailOpen := FALSE;
    xFltFailClose := FALSE;
    xFltPosLost := FALSE;
    xFltTorque := FALSE;
    xFltExt := FALSE;
    xResetWin := FALSE;
    uiFirstOut := GVL_Const.NO_FIRST_OUT;
END_IF
