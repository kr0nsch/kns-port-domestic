IF lrRate <= 0.0 THEN
    RateStep := lrTarget;
ELSIF lrStep_s <= 0.0 THEN
    RateStep := lrCurrent;
ELSIF lrTarget > lrCurrent THEN
    RateStep := MIN(lrTarget, lrCurrent + lrRate * lrStep_s);
ELSE
    RateStep := MAX(lrTarget, lrCurrent - lrRate * lrStep_s);
END_IF
