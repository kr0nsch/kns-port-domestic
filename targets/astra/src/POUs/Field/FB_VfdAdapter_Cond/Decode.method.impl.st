xCommOk := xSlaveOk;
IF xSlaveOk THEN
    xReady := (wStw AND GVL_Const.VFD_STW_READY) <> 0;
    xRunning := (wStw AND GVL_Const.VFD_STW_RUNNING) <> 0;
    xFault := (wStw AND GVL_Const.VFD_STW_FAULT) <> 0;
    xWarning := (wStw AND GVL_Const.VFD_STW_WARNING) <> 0;
    xRemote := (wStw AND GVL_Const.VFD_STW_REMOTE) <> 0;
    rSpeedAct_pct := UINT_TO_REAL(uiFact) / GVL_Const.VFD_COUNTS_PER_PCT;
ELSE
    // регистры без связи замирают: слово состояния недостоверно, скорость — последняя принятая
    xReady := FALSE;
    xRunning := FALSE;
    xFault := FALSE;
    xWarning := FALSE;
    xRemote := FALSE;
END_IF
