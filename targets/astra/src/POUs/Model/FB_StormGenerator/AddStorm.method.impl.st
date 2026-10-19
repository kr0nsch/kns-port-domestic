lrDur_s := PL.F_TimeToSec(tIn := tDur);
lrTau_s := (lrClock_h - lrStartAt_h) * REAL_TO_LREAL(GVL_Const.SIM_S_PER_H);
IF lrDur_s <= 0.0 OR lrTau_s < 0.0 OR lrTau_s >= lrDur_s THEN
    RETURN;
END_IF

xActive := TRUE;
lrRise_s := REAL_TO_LREAL(GVL_Const.SIM_STORM_RISE_SHARE) * lrDur_s;
lrFall_s := (1.0 - REAL_TO_LREAL(GVL_Const.SIM_STORM_FALL_SHARE)) * lrDur_s;
IF lrTau_s < lrRise_s THEN
    rInflow_m3h := rInflow_m3h + LREAL_TO_REAL(REAL_TO_LREAL(rPeak) * lrTau_s / lrRise_s);
ELSIF lrTau_s < lrFall_s THEN
    rInflow_m3h := rInflow_m3h + rPeak;
ELSE
    rInflow_m3h := rInflow_m3h
                   + LREAL_TO_REAL(REAL_TO_LREAL(rPeak) * (lrDur_s - lrTau_s) / (lrDur_s - lrFall_s));
END_IF
