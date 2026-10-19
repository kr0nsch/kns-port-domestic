xIntakeDry := lrLevel_m < REAL_TO_LREAL(GVL_Const.SIM_PUMP_INTAKE_M);
xOverflow := FALSE;

IF lrDt_s > 0.0 AND rArea_m2 > 0.0 AND PL.F_IsFinite(rIn := rInflow_m3h) AND PL.F_IsFinite(rIn := rOutflow_m3h)
   AND PL.F_IsFinite(rIn := rArea_m2) THEN
    // осушенный приёмок: насосы подсасывают воздух и не откачивают
    IF xIntakeDry THEN
        lrOut_m3h := 0.0;
    ELSE
        lrOut_m3h := REAL_TO_LREAL(MAX(rOutflow_m3h, 0.0));
    END_IF
    lrLevel_m := lrLevel_m + (REAL_TO_LREAL(MAX(rInflow_m3h, 0.0)) - lrOut_m3h) * lrDt_s
                 / REAL_TO_LREAL(GVL_Const.SIM_S_PER_H) / REAL_TO_LREAL(rArea_m2);
    IF lrLevel_m >= REAL_TO_LREAL(rOverflow_m) THEN
        lrLevel_m := REAL_TO_LREAL(rOverflow_m);
        IF REAL_TO_LREAL(rInflow_m3h) > lrOut_m3h THEN
            xOverflow := TRUE;
            lrOverflow_s := lrOverflow_s + lrDt_s;
        END_IF
    END_IF
    IF lrLevel_m < 0.0 THEN
        lrLevel_m := 0.0;
    END_IF
END_IF

xIntakeDry := lrLevel_m < REAL_TO_LREAL(GVL_Const.SIM_PUMP_INTAKE_M);
rLevel_m := LREAL_TO_REAL(lrLevel_m);
rVolume_m3 := rLevel_m * rArea_m2;
udiOverflow_s := LREAL_TO_UDINT(lrOverflow_s);
IF udiOverflow_s = 0 AND lrOverflow_s > 0.0 THEN
    udiOverflow_s := 1;     // перелив короче 0,5 с при округлении дал бы 0: любой перелив виден
END_IF
