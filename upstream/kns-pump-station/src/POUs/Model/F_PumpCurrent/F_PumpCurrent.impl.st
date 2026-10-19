F_PumpCurrent := 0.0;
IF NOT (PL.F_IsFinite(rIn := rFlow_m3h) AND PL.F_IsFinite(rIn := rHead_m) AND PL.F_IsFinite(rIn := rSpeed)) THEN
    RETURN;
END_IF
IF rSpeed <= 0.0 OR stPump.rPnom_kW <= 0.0 OR stPump.rEta <= 0.0 THEN
    RETURN;
END_IF

rHyd_kW := GVL_Const.SIM_RHO_KGM3 * GVL_Const.SIM_GRAVITY_MPS2 * (MAX(rFlow_m3h, 0.0) / GVL_Const.SIM_S_PER_H)
           * MAX(rHead_m, 0.0) / GVL_Const.SIM_W_PER_KW;
rLoss_kW := stPump.rLossShare * stPump.rPnom_kW * rSpeed * rSpeed * rSpeed;
rIn_kW := MAX(rHyd_kW / stPump.rEta, rLoss_kW);
F_PumpCurrent := stPump.rImagShare * stPump.rInom_A * rSpeed
                 + (1.0 - stPump.rImagShare) * stPump.rInom_A * rIn_kW / stPump.rPnom_kW;
