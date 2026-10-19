xLowCut := FALSE;
xClamped := FALSE;
IF xCompute THEN
    // нормировка: x — доли шкалы
    lrLo := REAL_TO_LREAL(stCfgLkg.rRangeLo_eu);
    lrSpan := REAL_TO_LREAL(stCfgLkg.rRangeHi_eu) - lrLo;
    IF stCfgLkg.eInput = E_AiInputType.MilliAmp THEN
        lrX := (REAL_TO_LREAL(rIn) - REAL_TO_LREAL(GVL_Const.MA_ZERO)) / REAL_TO_LREAL(GVL_Const.MA_SPAN);
    ELSIF stCfgLkg.eInput = E_AiInputType.Eng THEN
        lrX := (REAL_TO_LREAL(rIn) - lrLo) / lrSpan;
    ELSIF stCfgLkg.eInput = E_AiInputType.Raw THEN
        lrX := (REAL_TO_LREAL(rIn) - REAL_TO_LREAL(stCfgLkg.rRawLo_cnt))
               / (REAL_TO_LREAL(stCfgLkg.rRawHi_cnt) - REAL_TO_LREAL(stCfgLkg.rRawLo_cnt));
    ELSE
        // Norm420, Norm01: вход уже в долях шкалы
        lrX := REAL_TO_LREAL(rIn);
    END_IF
    // NE 43: за насыщением 3,8 / 20,5 мА измерения нет — это защитные полосы до порогов отказа (ток отказа с
    // погрешностью канала или насыщение датчика). Значение не экстраполируется дальше насыщения (AI-13)
    IF stCfgLkg.eInput = E_AiInputType.MilliAmp OR stCfgLkg.eInput = E_AiInputType.Norm420 THEN
        lrXLo := (REAL_TO_LREAL(GVL_Const.NE43_MEAS_LOW_MA) - REAL_TO_LREAL(GVL_Const.MA_ZERO))
                 / REAL_TO_LREAL(GVL_Const.MA_SPAN);
        lrXHi := (REAL_TO_LREAL(GVL_Const.NE43_MEAS_HIGH_MA) - REAL_TO_LREAL(GVL_Const.MA_ZERO))
                 / REAL_TO_LREAL(GVL_Const.MA_SPAN);
        lrX := LIMIT(lrXLo, lrX, lrXHi);
    END_IF

    // корень (расход по перепаду давления), затем отсечка — она действует и без корня
    IF stCfgLkg.xSqrt THEN
        lrX := SQRT(MAX(lrX, 0.0));
    END_IF
    IF stCfgLkg.rLowCut_pct > 0.0
       AND lrX * REAL_TO_LREAL(GVL_Const.PCT_FULL) < REAL_TO_LREAL(stCfgLkg.rLowCut_pct)
    THEN
        lrX := 0.0;
        xLowCut := TRUE;
    END_IF

    // инженерные единицы; по умолчанию — экстраполяция за шкалу, при xClamp — ограничение шкалой
    lrEng := lrLo + lrX * lrSpan;
    IF stCfgLkg.xClamp THEN
        IF lrEng < lrLo THEN
            lrEng := lrLo;
            xClamped := TRUE;
        ELSIF lrEng > lrLo + lrSpan THEN
            lrEng := lrLo + lrSpan;
            xClamped := TRUE;
        END_IF
    END_IF

    // фильтр: alpha = 1 - exp(-dt / T); T#0S, первый расчёт и расчёт после подтверждённого отказа — без фильтра
    lrT_s := F_TimeToSec(tIn := stCfgLkg.tFilter);
    IF xFltInit OR lrT_s <= 0.0 THEN
        lrFlt := lrEng;
    ELSE
        lrFlt := lrFlt + (1.0 - EXP(-F_LTimeToSec(ltIn := ltDt) / lrT_s)) * (lrEng - lrFlt);
    END_IF
    xFltInit := FALSE;

    // хорошее значение для удержания: пока отказ не подтверждён; |значение| не больше REAL_SANE_MAX
    IF NOT xFail THEN
        lrSane := REAL_TO_LREAL(GVL_Const.REAL_SANE_MAX);
        rGood_eu := LREAL_TO_REAL(LIMIT(-lrSane, lrFlt, lrSane));
        xHaveGood := TRUE;
    END_IF
ELSE
    // расчёта нет. Отказ подтверждён или сигнал не контролируется (xRestart): фильтр начнётся заново с
    // текущего значения. Неподтверждённый провал фильтр замораживает: после него — продолжение без скачка
    xFltInit := xFltInit OR xRestart;
END_IF
