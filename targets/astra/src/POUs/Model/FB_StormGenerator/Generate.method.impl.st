// начальное состояние суток; UDINT-умножение — по модулю 2^32
dwState := UDINT_TO_DWORD(udiSeed) XOR UDINT_TO_DWORD(udiForDay * GVL_Const.SIM_SEED_DAY_MUL);
IF dwState = 0 THEN
    dwState := GVL_Const.SIM_XS_ZERO_STATE;
END_IF

uiMax := MIN(uiStormsPerDayMax, GVL_Const.SIM_STORMS_MAX);
uiN := UDINT_TO_UINT(FloorU(lrValue := Draw() * UINT_TO_LREAL(uiMax + 1)));
uiN := MIN(uiN, uiMax);

lrMin_ms := UDINT_TO_LREAL(TIME_TO_UDINT(MIN(tDurationMin, tDurationMax)));
lrMax_ms := UDINT_TO_LREAL(TIME_TO_UDINT(MAX(tDurationMin, tDurationMax)));
rLoPeak := MIN(rPeakMin_m3h, rPeakMax_m3h);
rHiPeak := MAX(rPeakMin_m3h, rPeakMax_m3h);
FOR uiK := 1 TO uiN DO
    astWork[uiK].rStart_h := LREAL_TO_REAL(Draw() * REAL_TO_LREAL(GVL_Const.SIM_HOURS_PER_DAY));
    astWork[uiK].tDuration := UDINT_TO_TIME(LREAL_TO_UDINT(lrMin_ms + Draw() * (lrMax_ms - lrMin_ms)));
    astWork[uiK].rPeak_m3h := LREAL_TO_REAL(REAL_TO_LREAL(rLoPeak) + Draw() * REAL_TO_LREAL(rHiPeak - rLoPeak));
END_FOR
Generate := uiN;
