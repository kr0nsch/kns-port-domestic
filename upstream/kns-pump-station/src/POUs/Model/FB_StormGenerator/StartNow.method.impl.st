IF tDuration > T#0S AND rPeak_m3h > 0.0 AND PL.F_IsFinite(rIn := rPeak_m3h) THEN
    xManual := TRUE;
    lrManualStart_h := lrStartAt_h;
    stManual.rStart_h := 0.0;
    stManual.tDuration := tDuration;
    stManual.rPeak_m3h := rPeak_m3h;
ELSE
    xManual := FALSE;
END_IF
