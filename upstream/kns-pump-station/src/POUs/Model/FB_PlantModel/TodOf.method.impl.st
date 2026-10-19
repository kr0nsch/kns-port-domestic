lrDay_h := REAL_TO_LREAL(GVL_Const.SIM_HOURS_PER_DAY);
IF lrHours >= 0.0 THEN
    lrTod_h := lrHours - UDINT_TO_LREAL(DayOf(lrHours := lrHours)) * lrDay_h;
ELSIF lrHours < 0.0 THEN
    // отрицательное время суток из команды: −0,5 ч → 23,5 ч
    lrTod_h := lrDay_h - (-lrHours - UDINT_TO_LREAL(DayOf(lrHours := -lrHours)) * lrDay_h);
ELSE
    lrTod_h := 0.0;         // NaN
END_IF
IF lrTod_h >= lrDay_h OR lrTod_h < 0.0 THEN
    lrTod_h := 0.0;
END_IF
TodOf := LREAL_TO_REAL(lrTod_h);
