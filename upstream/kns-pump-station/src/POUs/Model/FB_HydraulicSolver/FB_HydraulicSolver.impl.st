// 1. Скорости (неконечная — как 0) и какие насосы могут подавать
xAnyClog := FALSE;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF PL.F_IsFinite(rIn := arSpeed[uiPump]) AND arSpeed[uiPump] > 0.0 THEN
        arS[uiPump] := arSpeed[uiPump];
    ELSE
        arS[uiPump] := 0.0;
    END_IF
    axActive[uiPump] := arS[uiPump] > 0.0 AND NOT axAirLock[uiPump] AND NOT xIntakeDry;
    arShutoff[uiPump] := stPump.rH0_m * arS[uiPump] * arS[uiPump];
    xAnyClog := xAnyClog OR (axClog[uiPump] AND axActive[uiPump]);
END_FOR

// 2. Рабочая точка с засорами и токи по ней
rHead_m := Solve(xWithClog := TRUE);
rFlow_m3h := 0.0;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    arFlow_m3h[uiPump] := arQ[uiPump];
    rFlow_m3h := rFlow_m3h + arQ[uiPump];
    arCurrent_A[uiPump] := F_PumpCurrent(rFlow_m3h := arQ[uiPump], rHead_m := rHead_m, rSpeed := arS[uiPump],
                                         stPump := stPump);
END_FOR

// 3. Засор: ток ×SIM_CLOG_I_FACTOR к току того же насоса в той же сети без засора — только у насоса, который
//    может подавать (при сухом ходе и осушенном приёмке воды в колесе нет: ток холостого хода, ниже порога
//    недогрузки)
IF xAnyClog THEN
    rHeadClean := Solve(xWithClog := FALSE);
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        IF axClog[uiPump] AND axActive[uiPump] THEN
            arCurrent_A[uiPump] := GVL_Const.SIM_CLOG_I_FACTOR
                                   * F_PumpCurrent(rFlow_m3h := arQ[uiPump], rHead_m := rHeadClean,
                                                   rSpeed := arS[uiPump], stPump := stPump);
        END_IF
    END_FOR
END_IF

// 4. Давление у дна коллектора: напор сети плюс уровень
rPressure_bar := GVL_Const.SIM_RHO_KGM3 * GVL_Const.SIM_GRAVITY_MPS2 * (rHead_m + rLevel_m) / GVL_Const.SIM_PA_PER_BAR;
