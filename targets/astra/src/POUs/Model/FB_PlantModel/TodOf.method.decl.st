// Время суток для часов модели lrHours: остаток от деления на 24 ч, в [0, 24); неконечное — 0
METHOD PRIVATE TodOf : REAL
VAR_INPUT
    lrHours : LREAL;        // часы модели (или время суток вне диапазона)
END_VAR
VAR
    lrDay_h : LREAL;        // 24 ч в LREAL
    lrTod_h : LREAL;        // остаток
END_VAR
