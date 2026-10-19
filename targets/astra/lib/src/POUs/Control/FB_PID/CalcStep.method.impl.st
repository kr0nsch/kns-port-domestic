lrPv_eu := REAL_TO_LREAL(rPv_eu);
// рампа задания; первый расчёт и слежение за PV берут цель сразу
IF xSpInit OR xSpFollow THEN
    lrSp_eu := lrSpTarget_eu;
    xSpInit := FALSE;
ELSE
    lrSp_eu := RateStep(lrCurrent := lrSp_eu, lrTarget := lrSpTarget_eu,
                        lrRate := REAL_TO_LREAL(stCfgLkg.rSpRate_ups), lrStep_s := lrStep_s);
END_IF
// ошибка со знаком действия, % диапазона PV
IF stCfgLkg.eAction = E_PidAction.Direct THEN
    lrSign := -1.0;
ELSE
    lrSign := 1.0;
END_IF
lrScale := REAL_TO_LREAL(GVL_Const.PCT_FULL)
           / (REAL_TO_LREAL(stCfgLkg.rPvMax_eu) - REAL_TO_LREAL(stCfgLkg.rPvMin_eu));
lrE_pct := lrSign * (lrSp_eu - lrPv_eu) * lrScale;
// зона нечувствительности
lrDb_pct := REAL_TO_LREAL(stCfgLkg.rDeadband_pct);
xInDeadband := lrDb_pct > 0.0 AND ABS(lrE_pct) <= lrDb_pct;
IF ABS(lrE_pct) <= lrDb_pct THEN
    lrErr_pct := 0.0;
ELSIF lrE_pct > 0.0 THEN
    lrErr_pct := lrE_pct - lrDb_pct;
ELSE
    lrErr_pct := lrE_pct + lrDb_pct;
END_IF
// P по ошибке, D по измерению
lrKp := REAL_TO_LREAL(stCfgLkg.rKp);
lrP_pct := lrKp * lrErr_pct;
lrTd_s := REAL_TO_LREAL(stCfgLkg.rTd_s);
IF lrTd_s > 0.0 AND NOT xInit THEN
    lrTf_s := lrTd_s / REAL_TO_LREAL(stCfgLkg.rDFilterN);
    lrD_pct := lrTf_s / (lrTf_s + lrStep_s) * lrD_pct
               - lrKp * lrTd_s / (lrTf_s + lrStep_s) * lrSign * (lrPv_eu - lrPvPrev_eu) * lrScale;
ELSE
    lrD_pct := 0.0;
END_IF
lrPvPrev_eu := lrPv_eu;
lrV_pct := lrP_pct + lrI_pct + lrD_pct;
