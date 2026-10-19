IF PL.F_IsFinite(rIn := rNewLevel_m) THEN
    lrLevel_m := REAL_TO_LREAL(LIMIT(0.0, rNewLevel_m, rOverflow_m));
    rLevel_m := LREAL_TO_REAL(lrLevel_m);
    xIntakeDry := lrLevel_m < REAL_TO_LREAL(GVL_Const.SIM_PUMP_INTAKE_M);
END_IF
