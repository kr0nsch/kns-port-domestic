IF NOT stCfg.xEnable OR xForceOff THEN
    // уставка выключена или принудительный сброс: флаг снимается сразу, отсчёт задержек —
    // заново после включения
    xRaw := FALSE;
    fbDelay.Preset(xValue := FALSE);
    xOut := FALSE;
ELSE
    IF itfTime <> 0 THEN
        itfTimeAct := itfTime;
    ELSE
        itfTimeAct := fbSysTime;
    END_IF

    // гистерезис: в зоне между порогами срабатывания и снятия флаг сохраняется
    IF xHighLimit THEN
        xNewRaw := (rValue_eu >= stCfg.rSetpoint_eu)
                   OR (xRaw AND (rValue_eu >= stCfg.rSetpoint_eu - stCfg.rHyst_eu));
    ELSE
        xNewRaw := (rValue_eu <= stCfg.rSetpoint_eu)
                   OR (xRaw AND (rValue_eu <= stCfg.rSetpoint_eu + stCfg.rHyst_eu));
    END_IF
    // неконечное значение (NaN, ±Inf, мусор) флаг не меняет
    xRaw := SEL(F_IsFinite(rIn := rValue_eu), xRaw, xNewRaw);

    fbDelay(xIn := xRaw, tOnDelay := stCfg.tOnDelay, tOffDelay := stCfg.tOffDelay, itfTime := itfTimeAct);
    xOut := fbDelay.xOut;
END_IF
