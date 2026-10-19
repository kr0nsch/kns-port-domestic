uiCount := Count(ltNow := ltNow);
IF uiMax = 0 OR uiCount < uiMax THEN
    TimeToFree := LTIME#0S;
ELSE
    // отметки упорядочены: должна истечь (uiCount - uiMax)-я от самой старой (с нуля).
    // Она в окне, поэтому ltNow - t < STARTS_WINDOW и результат больше нуля
    uiIdx := (uiNext + GVL_Const.STARTS_WINDOW_MAX - uiUsed + uiCount - uiMax) MOD GVL_Const.STARTS_WINDOW_MAX;
    TimeToFree := GVL_Const.STARTS_WINDOW - (ltNow - altStart[uiIdx]);
END_IF
