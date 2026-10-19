// 0. Время: шаг рампы от прошлого вызова; «время назад» — шаг 0
itfTimeAct := itfTime;
IF itfTimeAct = 0 THEN
    itfTimeAct := fbSysTime;
END_IF
ltNow := itfTimeAct.Now();
IF NOT xInit THEN
    xInit := TRUE;
    ltLast := ltNow;
    fbBoot.Preset(xValue := xPowerOk);      // ПЧ, включённый до старта модели, уже загружен
END_IF
IF ltNow >= ltLast THEN
    lrDt_s := PL.F_LTimeToSec(ltIn := ltNow - ltLast);
ELSE
    lrDt_s := 0.0;
END_IF
ltLast := ltNow;
IF xResetReq THEN
    fbBoot.Preset(xValue := xPowerOk);      // ResetDrive: плата управления считается загруженной
END_IF

// 1. Питание и загрузка платы управления
fbBoot(xIn := xPowerOk, tOnDelay := tBoot, itfTime := itfTimeAct);
IF NOT xPowerOk THEN
    IF xOutputActive THEN
        uiLastFcode := GVL_Const.SIM_VFD_FCODE_UNDERVOLT;   // питание пропало на ходу
    END_IF
    xFaulted := FALSE;      // обесточенный ПЧ теряет аварию; причина осталась — авария снова после загрузки
END_IF
xOn := xPowerOk AND fbBoot.xOut;

// 2. Связь: записи мастера доходят до ПЧ только при связи; без запросов — сторожевой таймер ПЧ
xCommOk := xOn AND NOT xCommLoss;
IF xCommOk THEN
    wCtwRx := wCtw;
    uiFrefRx := uiFref;
END_IF
fbWatchdog(xIn := xOn AND NOT xCommOk, tOnDelay := GVL_Const.SIM_VFD_WATCHDOG, itfTime := itfTimeAct);
xWatchdog := fbWatchdog.xOut;

// 3. Авария: фиксируется, снимается фронтом бита сброса после снятия причины
xResetBit := (wCtwRx AND GVL_Const.VFD_CTW_RESET) <> 0;
IF xOn AND (xFaultInj OR xOverheat) AND NOT xFaulted THEN
    xFaulted := TRUE;
    IF xOverheat THEN
        uiLastFcode := GVL_Const.SIM_VFD_FCODE_OVERHEAT;
    ELSE
        uiLastFcode := GVL_Const.SIM_VFD_FCODE_EXT;
    END_IF
ELSIF xFaulted AND xResetBit AND NOT xResetPrev AND NOT xFaultInj AND NOT xOverheat THEN
    xFaulted := FALSE;
END_IF
xResetPrev := xResetBit;
IF xResetReq THEN
    // ResetDrive («ПЧ готовы»): авария снимается, если её причины уже нет (по входам этого вызова)
    IF NOT xFaultInj AND NOT xOverheat THEN
        xFaulted := FALSE;
    END_IF
    xResetReq := FALSE;
END_IF

// 4. Задание (местный пост, предустановленная частота сторожевого таймера или FREF) и пуск
IF xLocal THEN
    // «Местное»: задание по сети не действует (FB_MotorVfd в Local следит за фактом — у стоящего насоса 0 %)
    rRef_Hz := GVL_Const.SIM_VFD_LOCAL_FREQ_HZ;
ELSIF xWatchdog THEN
    rRef_Hz := GVL_Const.SIM_VFD_WATCHDOG_FREQ_HZ;
ELSE
    rRef_Hz := UINT_TO_REAL(uiFrefRx) / GVL_Const.SIM_VFD_COUNTS_PER_HZ;
END_IF
rRef_Hz := LIMIT(0.0, rRef_Hz, GVL_Const.VFD_FREQ_NOM_HZ);
IF xLocal THEN
    xRunReq := xLocalRun;
ELSE
    xRunReq := xRunCmd;
END_IF
lrAccel_s := PL.F_TimeToSec(tIn := tAccel);
IF lrAccel_s > 0.0 THEN
    rRate_Hzps := GVL_Const.VFD_FREQ_NOM_HZ / LREAL_TO_REAL(lrAccel_s);
ELSE
    rRate_Hzps := 0.0;      // F_RateLimit: скорость 0 — без ограничения
END_IF

IF NOT xOn OR xFaulted THEN
    // выбег: инвертор выключен, насос останавливается столбом воды
    rFreq_Hz := 0.0;
    xOutputActive := FALSE;
ELSIF xRunReq THEN
    xOutputActive := TRUE;
    rFreq_Hz := PL.F_RateLimit(rCurrent := rFreq_Hz, rTarget := rRef_Hz, rRateUp_ups := rRate_Hzps,
                               rRateDown_ups := rRate_Hzps, lrDt_s := lrDt_s);
ELSIF xOutputActive THEN
    // торможение до 0 тем же темпом; реле «Работа» замкнуто до остановки
    rFreq_Hz := PL.F_RateLimit(rCurrent := rFreq_Hz, rTarget := 0.0, rRateUp_ups := rRate_Hzps,
                               rRateDown_ups := rRate_Hzps, lrDt_s := lrDt_s);
    IF rFreq_Hz <= 0.0 THEN
        rFreq_Hz := 0.0;
        xOutputActive := FALSE;
    END_IF
END_IF
xReady := xOn AND NOT xFaulted;

// 5. Релейные выходы с инъекциями
xRelayRun := (xOutputActive AND NOT xNoFeedback) OR xFeedbackStuck;
xRelayFault := xFaulted;

// 6. Регистры чтения: ПЧ обесточен или загружается — 0; нет связи — последние принятые мастером
IF NOT xOn THEN
    wStw := 0;
    uiFact := 0;
    uiCurrent := 0;
    uiFcode := 0;
ELSIF xCommOk THEN
    wStw := 0;
    IF xReady THEN
        wStw := wStw OR GVL_Const.VFD_STW_READY;
    END_IF
    IF xOutputActive THEN
        wStw := wStw OR GVL_Const.VFD_STW_RUNNING;
    END_IF
    IF xFaulted THEN
        wStw := wStw OR GVL_Const.VFD_STW_FAULT;
    END_IF
    IF NOT xLocal THEN
        wStw := wStw OR GVL_Const.VFD_STW_REMOTE;   // управление от клемм (дистанционное)
    END_IF
    uiFact := REAL_TO_UINT(rFreq_Hz * GVL_Const.SIM_VFD_COUNTS_PER_HZ);
    IF xOutputActive AND PL.F_IsFinite(rIn := rMotorCurrent_A) THEN
        uiCurrent := REAL_TO_UINT(LIMIT(0.0, rMotorCurrent_A * GVL_Const.SIM_IT_COUNTS_PER_A,
                                        UINT_TO_REAL(PL.GVL_Const.UINT_MAX)));
    ELSE
        uiCurrent := 0;
    END_IF
    uiFcode := uiLastFcode;
END_IF
