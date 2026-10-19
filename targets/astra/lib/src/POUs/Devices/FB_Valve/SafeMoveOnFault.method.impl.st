xMayMove := xMotorized AND xIlkAct AND xFaultAny AND xCfgEverOk AND xPowerOk AND NOT xFltExt AND NOT xFltTorque
            AND (stCfgLkg.eSafePos = E_ValveSafePos.Open OR stCfgLkg.eSafePos = E_ValveSafePos.Closed);
IF NOT xMayMove THEN
    xSafeMove := FALSE;
    IF NOT (xIlkAct AND xFaultAny) THEN
        // блокировка или отказы сняты: следующий эпизод — новый аварийный ход
        xSafeMoveDone := FALSE;
    END_IF
ELSIF NOT xSafeMove AND NOT xSafeMoveDone THEN
    IF stCfgLkg.eSafePos = E_ValveSafePos.Closed AND NOT (fbRunOff.xOut AND eLastDir = E_ValveState.Opening) THEN
        eSafeDir := E_ValveState.Closing;
        xSafeMove := TRUE;
    ELSIF stCfgLkg.eSafePos = E_ValveSafePos.Open AND NOT (fbRunOff.xOut AND eLastDir = E_ValveState.Closing) THEN
        eSafeDir := E_ValveState.Opening;
        xSafeMove := TRUE;
    END_IF
    IF xSafeMove THEN
        fbSafeMove.Preset(xValue := FALSE);
    END_IF
END_IF
fbSafeMove(xIn := xSafeMove, tOnDelay := stCfgLkg.tTravel, itfTime := itfTimeAct);
IF xSafeMove THEN
    IF eSafeDir = E_ValveState.Closing THEN
        xEnd := (xAtClose AND NOT xAtOpen) OR xTrqClose;
    ELSE
        xEnd := (xAtOpen AND NOT xAtClose) OR xTrqOpen;
    END_IF
    IF xEnd OR fbSafeMove.xOut THEN
        xSafeMove := FALSE;
        xSafeMoveDone := TRUE;
    END_IF
END_IF
