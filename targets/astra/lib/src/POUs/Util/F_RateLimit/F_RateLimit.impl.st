IF lrDt_s <= 0.0 OR NOT F_IsFinite(rIn := rTarget) THEN
    // шага нет или цель — мусор: значение не меняется
    F_RateLimit := rCurrent;
ELSIF rTarget > rCurrent AND rRateUp_ups > 0.0 THEN
    // рост, ограничен сверху
    lrLimit := REAL_TO_LREAL(rCurrent) + REAL_TO_LREAL(rRateUp_ups) * lrDt_s;
    F_RateLimit := LREAL_TO_REAL(MIN(REAL_TO_LREAL(rTarget), lrLimit));
ELSIF rTarget < rCurrent AND rRateDown_ups > 0.0 THEN
    // спад, ограничен снизу
    lrLimit := REAL_TO_LREAL(rCurrent) - REAL_TO_LREAL(rRateDown_ups) * lrDt_s;
    F_RateLimit := LREAL_TO_REAL(MAX(REAL_TO_LREAL(rTarget), lrLimit));
ELSE
    // цель достигнута, скорость не ограничена или текущее значение не число: сразу к цели
    F_RateLimit := rTarget;
END_IF
