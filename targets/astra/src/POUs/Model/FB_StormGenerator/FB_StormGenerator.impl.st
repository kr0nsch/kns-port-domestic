// 1. Сутки модели (часы не бывают отрицательными: модель начинает с 0…24 ч)
IF lrClock_h > 0.0 THEN
    udiDay := FloorU(lrValue := lrClock_h / REAL_TO_LREAL(GVL_Const.SIM_HOURS_PER_DAY));
ELSE
    udiDay := 0;
END_IF

// 2. Ливни текущих и предыдущих суток — заново при смене суток или параметров генератора
IF NOT xGenerated OR udiDay <> udiDayGen OR udiSeed <> udiSeedGen OR uiStormsPerDayMax <> uiMaxGen
   OR rPeakMin_m3h <> rPeakMinGen OR rPeakMax_m3h <> rPeakMaxGen OR tDurationMin <> tMinGen
   OR tDurationMax <> tMaxGen THEN
    uiCount := Generate(udiForDay := udiDay);
    astStorm := astWork;
    IF udiDay > 0 THEN
        uiPrevCount := Generate(udiForDay := udiDay - 1);
        astPrev := astWork;
    ELSE
        uiPrevCount := 0;
    END_IF
    xGenerated := TRUE;
    udiDayGen := udiDay;
    udiSeedGen := udiSeed;
    uiMaxGen := uiStormsPerDayMax;
    rPeakMinGen := rPeakMin_m3h;
    rPeakMaxGen := rPeakMax_m3h;
    tMinGen := tDurationMin;
    tMaxGen := tDurationMax;
END_IF

// 3. Приток: сумма трапеций идущих ливней; ливни, начавшиеся до Clear, сняты
rInflow_m3h := 0.0;
xActive := FALSE;
FOR uiStorm := 1 TO uiPrevCount DO
    lrStart_h := UDINT_TO_LREAL(udiDay - 1) * REAL_TO_LREAL(GVL_Const.SIM_HOURS_PER_DAY)
                 + REAL_TO_LREAL(astPrev[uiStorm].rStart_h);
    IF lrStart_h >= lrSuppress_h THEN
        AddStorm(lrStartAt_h := lrStart_h, tDur := astPrev[uiStorm].tDuration, rPeak := astPrev[uiStorm].rPeak_m3h);
    END_IF
END_FOR
FOR uiStorm := 1 TO uiCount DO
    lrStart_h := UDINT_TO_LREAL(udiDay) * REAL_TO_LREAL(GVL_Const.SIM_HOURS_PER_DAY)
                 + REAL_TO_LREAL(astStorm[uiStorm].rStart_h);
    IF lrStart_h >= lrSuppress_h THEN
        AddStorm(lrStartAt_h := lrStart_h, tDur := astStorm[uiStorm].tDuration, rPeak := astStorm[uiStorm].rPeak_m3h);
    END_IF
END_FOR
IF xManual THEN
    IF (lrClock_h - lrManualStart_h) * REAL_TO_LREAL(GVL_Const.SIM_S_PER_H)
       >= PL.F_TimeToSec(tIn := stManual.tDuration) THEN
        xManual := FALSE;       // внеочередной ливень закончился
    ELSE
        AddStorm(lrStartAt_h := lrManualStart_h, tDur := stManual.tDuration, rPeak := stManual.rPeak_m3h);
    END_IF
END_IF
