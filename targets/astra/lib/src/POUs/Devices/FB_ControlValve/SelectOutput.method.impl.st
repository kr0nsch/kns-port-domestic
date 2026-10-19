xSafe := FALSE;
xRamping := FALSE;
xLimMin := FALSE;
xLimMax := FALSE;
xSpInvalid := FALSE;
IF NOT xCfgEverOk THEN
    // корректной Cfg не было: положение безопасности из поданной Cfg, в 0…100; NaN — 0
    rSafe_pct := rCfgSafePos_pct;
    IF F_IsFinite(rIn := rSafe_pct) THEN
        rSpAct := LIMIT(0.0, rSafe_pct, GVL_Const.PCT_FULL);
    ELSE
        rSpAct := 0.0;
    END_IF
    lrRamp_pct := REAL_TO_LREAL(rSpAct);
    xSafe := TRUE;
ELSIF eMode = E_DeviceMode.OutOfService THEN
    rSpAct := LREAL_TO_REAL(lrRamp_pct);
ELSIF eMode = E_DeviceMode.Local THEN
    // позиционер на месте: выход следит за ОС (возврат без рывка), без ОС — удержание. ОС датчика
    // чуть выходит за 0…100 % (-1 %, 102 %) — выход в пределах хода, ток не выходит из 4…20 мА
    IF xFbOk THEN
        lrRamp_pct := REAL_TO_LREAL(LIMIT(0.0, rPosFb_pct, GVL_Const.PCT_FULL));
    END_IF
    rSpAct := LREAL_TO_REAL(lrRamp_pct);
ELSIF xIlkAct OR (xFaultAny AND stCfgLkg.eFaultAction = E_CvFaultAction.SafePos) THEN
    // блокировка и отказ с SafePos: мимо пределов и рампы — безопасность важнее плавности
    lrRamp_pct := REAL_TO_LREAL(stCfgLkg.rSafePos_pct);
    xSafe := TRUE;
    rSpAct := stCfgLkg.rSafePos_pct;
ELSIF xFaultAny THEN
    rSpAct := LREAL_TO_REAL(lrRamp_pct);
ELSE
    IF eMode = E_DeviceMode.Auto THEN
        rSpRaw := rPosSpAuto_pct;
    ELSE
        rSpRaw := rManSp_pct;
    END_IF
    IF F_IsFinite(rIn := rSpRaw) THEN
        rSpAct := LIMIT(stCfgLkg.rOutMin_pct, rSpRaw, stCfgLkg.rOutMax_pct);
        xLimMin := rSpRaw < stCfgLkg.rOutMin_pct;
        xLimMax := rSpRaw > stCfgLkg.rOutMax_pct;
        // рампа в LREAL (CV-14): приращение медленной рампы при коротком цикле не теряется округлением до REAL
        IF lrDt_s > 0.0 THEN
            lrRamp_pct := F_RateLimitLr(lrCurrent := lrRamp_pct, rTarget := rSpAct,
                                        rRateUp_ups := stCfgLkg.rRateUp_pctps,
                                        rRateDown_ups := stCfgLkg.rRateDown_pctps, lrDt_s := lrDt_s);
        ELSIF (REAL_TO_LREAL(rSpAct) > lrRamp_pct AND stCfgLkg.rRateUp_pctps <= 0.0)
              OR (REAL_TO_LREAL(rSpAct) < lrRamp_pct AND stCfgLkg.rRateDown_pctps <= 0.0)
        THEN
            // шага времени нет (первый вызов, время назад), а скорость не ограничена — сразу к заданию
            lrRamp_pct := REAL_TO_LREAL(rSpAct);
        END_IF
        xRamping := lrRamp_pct <> REAL_TO_LREAL(rSpAct);
    ELSE
        // NaN из Modbus/ПИД: удержание и предупреждение
        xSpInvalid := TRUE;
        rSpAct := LREAL_TO_REAL(lrRamp_pct);
    END_IF
END_IF
