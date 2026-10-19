IF xRequest THEN
    uiFirstOut := GVL_Const.NO_FIRST_OUT;
    SetCmdResult(eResult := E_CmdResult.Accepted);
    IF xFltFailOpen OR xFltFailClose OR xFltPosLost OR xFltTorque OR xFltExt THEN
        xResetWin := TRUE;
        fbResetWin.Preset(xValue := FALSE);
    END_IF
END_IF
fbResetWin(xIn := xResetWin, tOnDelay := stCfgLkg.tResetWindow, itfTime := itfTimeAct);
IF xResetWin THEN
    // отказы хода и положения: привод стоит, причина в прошлом — снимаются сразу
    xFltFailOpen := FALSE;
    xFltFailClose := FALSE;
    xFltPosLost := FALSE;
    IF NOT xTrqOpen AND NOT xTrqClose THEN
        xFltTorque := FALSE;
    END_IF
    IF NOT xExtFault THEN
        xFltExt := FALSE;
    END_IF
    IF NOT xFltTorque AND NOT xFltExt THEN
        xResetWin := FALSE;
    ELSIF fbResetWin.xOut THEN
        SetCmdResult(eResult := E_CmdResult.RejectedFault);
        xResetWin := FALSE;
    END_IF
END_IF
