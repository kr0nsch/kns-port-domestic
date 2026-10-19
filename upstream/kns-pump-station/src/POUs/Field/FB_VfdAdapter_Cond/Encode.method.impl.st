wCtw := SEL(xQReset, 0, GVL_Const.VFD_CTW_RESET);
IF PL.F_IsFinite(rIn := rSpeedRef_pct) THEN
    uiFref := REAL_TO_UINT(LIMIT(0.0, rSpeedRef_pct, PL.GVL_Const.PCT_FULL) * GVL_Const.VFD_COUNTS_PER_PCT);
ELSE
    uiFref := 0;
END_IF
