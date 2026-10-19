FlowsAt := 0.0;
FOR uiJ := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF axActive[uiJ] AND arShutoff[uiJ] > rHead_m AND arK[uiJ] > 0.0 THEN
        arQ[uiJ] := SQRT((arShutoff[uiJ] - rHead_m) / arK[uiJ]);
    ELSE
        arQ[uiJ] := 0.0;
    END_IF
    FlowsAt := FlowsAt + arQ[uiJ];
END_FOR
