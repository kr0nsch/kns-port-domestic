lrTarget := REAL_TO_LREAL(rTarget);
IF lrDt_s <= 0.0 OR NOT F_IsFinite(rIn := rTarget) THEN
    // шага нет или цель — мусор: значение не меняется
    F_RateLimitLr := lrCurrent;
ELSIF lrTarget > lrCurrent AND rRateUp_ups > 0.0 THEN
    // рост, ограничен сверху
    F_RateLimitLr := MIN(lrTarget, lrCurrent + REAL_TO_LREAL(rRateUp_ups) * lrDt_s);
ELSIF lrTarget < lrCurrent AND rRateDown_ups > 0.0 THEN
    // спад, ограничен снизу
    F_RateLimitLr := MAX(lrTarget, lrCurrent - REAL_TO_LREAL(rRateDown_ups) * lrDt_s);
ELSE
    // цель достигнута, скорость не ограничена или текущее значение не число: сразу к цели
    F_RateLimitLr := lrTarget;
END_IF
