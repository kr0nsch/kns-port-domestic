rStatic := stPump.rHgeo_m - rLevel_m;
rHi := rStatic;
FOR uiI := 1 TO GVL_Const.STN_PUMP_COUNT DO
    arQ[uiI] := 0.0;
    IF xWithClog AND axClog[uiI] THEN
        arK[uiI] := stPump.rK_mh2 * GVL_Const.SIM_CLOG_K_FACTOR;
    ELSE
        arK[uiI] := stPump.rK_mh2;
    END_IF
    IF axActive[uiI] AND arShutoff[uiI] > rHi THEN
        rHi := arShutoff[uiI];
    END_IF
END_FOR

// ни один насос не преодолевает статический напор (или характеристика неверна) — обратные клапаны закрыты
IF rHi <= rStatic OR stPump.rK_mh2 <= 0.0 OR stPump.rR_mh2 < 0.0 THEN
    Solve := rStatic;
    RETURN;
END_IF

// f(H) = Hst + R·Q(H)² − H убывает по H: f(Hst) ≥ 0, f(max H0·s²) < 0
rLo := rStatic;
FOR uiIter := 1 TO GVL_Const.SIM_SOLVER_ITERATIONS DO
    rMid := (rLo + rHi) / 2.0;
    rTotal := FlowsAt(rHead_m := rMid);
    IF rStatic + stPump.rR_mh2 * rTotal * rTotal > rMid THEN
        rLo := rMid;
    ELSE
        rHi := rMid;
    END_IF
END_FOR
Solve := (rLo + rHi) / 2.0;
rTotal := FlowsAt(rHead_m := Solve);
