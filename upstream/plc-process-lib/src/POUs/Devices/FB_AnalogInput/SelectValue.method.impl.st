IF NOT xCfgEverOk THEN
    // безопасное значение: корректной Cfg ещё не было
    rValue_eu := 0.0;
    xValid := FALSE;
ELSIF eMode = E_DeviceMode.OutOfService THEN
    // значение удерживается
    xValid := FALSE;
ELSIF eMode = E_DeviceMode.Manual THEN
    // подмена без фильтра; неконечное значение подмены не принимается (значение удерживается)
    IF F_IsFinite(rIn := rSubst_eu) THEN
        rValue_eu := rSubst_eu;
    END_IF
    xValid := TRUE;
ELSIF xValueBad THEN
    IF stCfgLkg.eFailValue = E_AiFailValue.Substitute THEN
        rValue_eu := stCfgLkg.rFailValue_eu;
    ELSE
        rValue_eu := rGood_eu;
    END_IF
    xValid := FALSE;
ELSE
    // хорошее значение, значение насыщения NE 43 или последнее хорошее до подтверждения отказа
    // (AI_STS_FAIL_PENDING). Подтверждённый выход за диапазон — для управления непригодно (AI-13): ПИД и
    // автоматика не работают по значению, за которым процесс неизвестен (ток отказа NAMUR, прочитанный с
    // погрешностью канала, тоже попадает в защитную полосу); уставки по нему считаются
    rValue_eu := rGood_eu;
    xValid := NOT xOor;
END_IF

IF xCfgEverOk THEN
    lrSane := REAL_TO_LREAL(GVL_Const.REAL_SANE_MAX);
    rValue_pct := LREAL_TO_REAL(LIMIT(-lrSane,
                                      (REAL_TO_LREAL(rValue_eu) - REAL_TO_LREAL(stCfgLkg.rRangeLo_eu))
                                      / (REAL_TO_LREAL(stCfgLkg.rRangeHi_eu) - REAL_TO_LREAL(stCfgLkg.rRangeLo_eu))
                                      * REAL_TO_LREAL(GVL_Const.PCT_FULL),
                                      lrSane));
ELSE
    rValue_pct := 0.0;
END_IF
