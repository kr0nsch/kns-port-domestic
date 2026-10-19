// 1. Время суток по модулю 24 ч (в том числе отрицательное)
IF PL.F_IsFinite(rIn := rTimeOfDay_h) THEN
    rTod_h := rTimeOfDay_h
              - GVL_Const.SIM_HOURS_PER_DAY * DINT_TO_REAL(TRUNC(rTimeOfDay_h / GVL_Const.SIM_HOURS_PER_DAY));
    IF rTod_h < 0.0 THEN
        rTod_h := rTod_h + GVL_Const.SIM_HOURS_PER_DAY;
    END_IF
    IF rTod_h >= GVL_Const.SIM_HOURS_PER_DAY THEN
        rTod_h := 0.0;
    END_IF
ELSE
    rTod_h := 0.0;
END_IF

// 2. Интерполяция между соседними точками; после последней — первая
rPos := rTod_h * UINT_TO_REAL(GVL_Const.SIM_PROFILE_POINTS) / GVL_Const.SIM_HOURS_PER_DAY;
diIndex := LIMIT(0, TRUNC(rPos), UINT_TO_DINT(GVL_Const.SIM_PROFILE_POINTS) - 1);
uiLeft := DINT_TO_UINT(diIndex);
uiRight := (uiLeft + 1) MOD GVL_Const.SIM_PROFILE_POINTS;
rFactor := arProfile[uiLeft] + (arProfile[uiRight] - arProfile[uiLeft]) * (rPos - DINT_TO_REAL(diIndex));

IF PL.F_IsFinite(rIn := rFactor) AND PL.F_IsFinite(rIn := rAverage_m3h) THEN
    rInflow_m3h := MAX(0.0, rAverage_m3h * rFactor);
ELSE
    rInflow_m3h := 0.0;
END_IF
