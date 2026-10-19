lrDays := lrHours / REAL_TO_LREAL(GVL_Const.SIM_HOURS_PER_DAY);
// NaN: оба сравнения ложны — сутки 0
IF NOT (lrDays > 0.0) OR NOT (lrDays < UDINT_TO_LREAL(GVL_Const.SIM_DAY_MAX)) THEN
    DayOf := 0;
    RETURN;
END_IF
udiDays := LREAL_TO_UDINT(lrDays);          // округление к ближайшему — поправка вниз
IF UDINT_TO_LREAL(udiDays) > lrDays THEN
    udiDays := udiDays - 1;
END_IF
DayOf := udiDays;
