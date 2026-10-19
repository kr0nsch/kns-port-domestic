lrOutMin_pct := REAL_TO_LREAL(stCfgLkg.rOutMin_pct);
lrOutMax_pct := REAL_TO_LREAL(stCfgLkg.rOutMax_pct);
xTrackAct := FALSE;
IF NOT xCfgEverOk THEN
    // расчёта нет: выход от оператора в пределах 0…100 %; неконечное значение — выход прежний
    IF F_IsFinite(rIn := rManualOut_pct) THEN
        lrOut_pct := LIMIT(0.0, REAL_TO_LREAL(rManualOut_pct), REAL_TO_LREAL(GVL_Const.PCT_FULL));
    END_IF
    xOutRateLim := FALSE;
ELSIF eMode = E_DeviceMode.OutOfService THEN
    // выход удерживается, расчёта нет
    lrI_pct := lrOut_pct - lrP_pct - lrD_pct;
    xOutRateLim := FALSE;
ELSIF xTrack THEN
    // слежение: без пределов (механизм может стоять на 0); неконечное значение — выход прежний
    xTrackAct := TRUE;
    IF F_IsFinite(rIn := rTrack_pct) THEN
        lrOut_pct := REAL_TO_LREAL(rTrack_pct);
    END_IF
    lrI_pct := lrOut_pct - lrP_pct - lrD_pct;
    xOutRateLim := FALSE;
ELSIF eMode = E_DeviceMode.Manual THEN
    IF F_IsFinite(rIn := rManualOut_pct) THEN
        lrOut_pct := LIMIT(lrOutMin_pct, REAL_TO_LREAL(rManualOut_pct), lrOutMax_pct);
    END_IF
    lrI_pct := lrOut_pct - lrP_pct - lrD_pct;
    xOutRateLim := FALSE;
ELSIF NOT xPvOk THEN
    // Auto, PV негодна: Hold — выход удерживается, SafeOut — rSafeOut_pct; интегратор заморожен,
    // возврат PV — шаг инициализации (I := u - P): без рывка
    IF stCfgLkg.ePvFailAction = E_PidPvFailAction.SafeOut THEN
        lrOut_pct := REAL_TO_LREAL(stCfgLkg.rSafeOut_pct);
    END_IF
    xOutRateLim := FALSE;
ELSIF xCalcNow AND xInit THEN
    // шаг инициализации: выход прежний, интегрирования нет
    lrI_pct := lrOut_pct - lrP_pct - lrD_pct;
    xOutRateLim := FALSE;
ELSIF xCalcNow THEN
    // Auto: пределы, ограничение скорости, обратный расчёт по u или по rOutAct_pct
    lrULim_pct := LIMIT(lrOutMin_pct, lrV_pct, lrOutMax_pct);
    lrOut_pct := RateStep(lrCurrent := lrOut_pct, lrTarget := lrULim_pct,
                          lrRate := REAL_TO_LREAL(stCfgLkg.rOutRate_pctps), lrStep_s := lrStep_s);
    xOutRateLim := lrOut_pct <> lrULim_pct;
    IF stCfgLkg.xUseOutAct AND F_IsFinite(rIn := rOutAct_pct) THEN
        lrUAw_pct := REAL_TO_LREAL(rOutAct_pct);
    ELSE
        lrUAw_pct := lrOut_pct;
    END_IF
    lrKp := REAL_TO_LREAL(stCfgLkg.rKp);
    lrTi_s := REAL_TO_LREAL(stCfgLkg.rTi_s);
    lrTd_s := REAL_TO_LREAL(stCfgLkg.rTd_s);
    IF lrTi_s > 0.0 THEN
        // Tt: rTt_s, если задана; иначе SQRT(Ti·Td) при Td > 0; иначе Ti
        IF stCfgLkg.rTt_s > 0.0 THEN
            lrTt_s := REAL_TO_LREAL(stCfgLkg.rTt_s);
        ELSIF lrTd_s > 0.0 THEN
            lrTt_s := SQRT(lrTi_s * lrTd_s);
        ELSE
            lrTt_s := lrTi_s;
        END_IF
        lrI_pct := lrI_pct + lrKp * lrStep_s / lrTi_s * lrErr_pct
                   + MIN(lrStep_s / lrTt_s, 1.0) * (lrUAw_pct - lrV_pct);
    END_IF
END_IF
rOut_pct := LREAL_TO_REAL(lrOut_pct);
xSatHigh := xCfgEverOk AND lrOut_pct >= lrOutMax_pct;
xSatLow := xCfgEverOk AND lrOut_pct <= lrOutMin_pct;
