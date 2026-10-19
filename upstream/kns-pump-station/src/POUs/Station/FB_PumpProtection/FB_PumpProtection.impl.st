// 1. Сброс фиксации: импульс сброса насоса, кнопка HS501 или «Сбросить все» (04 §9.2). Насос под
//    блокировкой стоит, поэтому после сброса условие недогрузки отсчитывается заново
IF xReset THEN
    xUnderloadTrip := FALSE;
    fbUnderload.Preset(xValue := FALSE);
END_IF

// 2. Недогрузка (04 §10.3); неконечные ток и скорость — сравнения ложны, условия нет
xCond := stCfg.rUnderload_A > 0.0 AND xRunning AND xCurrentValid
         AND rSpeedAct_pct >= stCfg.rUnderloadSpeed_pct AND rCurrent_A < stCfg.rUnderload_A
         AND PL.F_IsFinite(rIn := rCurrent_A);
fbUnderload(xIn := xCond, tOnDelay := stCfg.tUnderload, itfTime := itfTime);
IF fbUnderload.xOut THEN
    xUnderloadTrip := TRUE;
END_IF
xUnderloadTiming := fbUnderload.xTimingOn;

// 3. Блокировки насоса: недогрузка — до сброса, перегрев — пока сигнал активен (04 §10.6)
wInterlock := 0;
IF xUnderloadTrip THEN
    wInterlock := wInterlock OR GVL_Const.KNS_ILK_UNDERLOAD;
END_IF
IF xOverheat THEN
    wInterlock := wInterlock OR GVL_Const.KNS_ILK_OVERHEAT;
END_IF
