IF PL.F_IsFinite(rIn := rTimeScale) THEN
    lrScaleNew := REAL_TO_LREAL(LIMIT(1.0, rTimeScale, GVL_Const.SIM_TIME_SCALE_MAX));
ELSE
    lrScaleNew := 1.0;
END_IF

ltReal := LTIME();
IF NOT xInit THEN
    xInit := TRUE;
    ltBaseReal := ltReal;
    ltBaseScaled := ltReal;
END_IF

IF lrScaleNew <> lrScaleAct THEN
    // перебазирование одним чтением системного времени: Now() непрерывно в точке смены
    ltBaseScaled := ScaledAt(ltReal := ltReal);
    ltBaseReal := ltReal;
    lrScaleAct := lrScaleNew;
END_IF
