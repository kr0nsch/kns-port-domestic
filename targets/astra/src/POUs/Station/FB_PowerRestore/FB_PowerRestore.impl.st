// 1. Переходы по питанию (диаграмма 04 §13.2). В первом вызове xPowerOk ещё не посчитан
//    устройством (станция вызывается до PRG_Devices): старт ПЛК — сразу «задержка» tPlcStart
IF xFirstCall THEN
    xDelay := TRUE;
    xPlcStart := TRUE;
    xLost := FALSE;
    xSeq := FALSE;
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.RestartBegin, rValue := 0.0);
    END_IF
ELSIF NOT xPowerOk THEN
    IF NOT xLost THEN
        xLost := TRUE;
        xDelay := FALSE;
        xSeq := FALSE;
        IF itfEvents <> 0 THEN
            itfEvents.LogEvent(eEvent := E_StationEvent.PowerLost, rValue := 0.0);
        END_IF
    END_IF
ELSIF xLost THEN
    xLost := FALSE;
    xDelay := TRUE;
    xPlcStart := FALSE;
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.RestartBegin, rValue := 0.0);
    END_IF
END_IF

// 2. Задержка после старта или восстановления; затем первый шаг
fbDelay(xIn := xDelay, tOnDelay := SEL(xPlcStart, stCfg.tPwrRestart, stCfg.tPlcStart), itfTime := itfTime);
IF xDelay AND fbDelay.xOut THEN
    xDelay := FALSE;
    xSeq := TRUE;
    uiStep := 1;
    xConfirmed := FALSE;
    fbStepWait.Preset(xValue := FALSE);
    fbStepTimeout.Preset(xValue := FALSE);
END_IF

// 3. Шаги: следующий запрос — через tSeqStep после подтверждения пусков шага (ОС), либо через
//    STN_SEQ_START_TIMEOUT, если пуск не подтвердился
IF xSeq AND NOT xConfirmed AND uiRunningRequested >= uiStep THEN
    xConfirmed := TRUE;
END_IF
fbStepWait(xIn := xSeq AND xConfirmed, tOnDelay := stCfg.tSeqStep, itfTime := itfTime);
fbStepTimeout(xIn := xSeq AND NOT xConfirmed, tOnDelay := GVL_Const.STN_SEQ_START_TIMEOUT, itfTime := itfTime);
xAdvance := xSeq AND uiStep < uiRequired AND (fbStepWait.xOut OR fbStepTimeout.xOut);
IF xAdvance THEN
    uiStep := uiStep + 1;
    xConfirmed := FALSE;
    fbStepWait.Preset(xValue := FALSE);
    fbStepTimeout.Preset(xValue := FALSE);
END_IF
IF xSeq AND uiStep >= uiRequired AND (uiRunningRequested >= uiRequired OR fbStepTimeout.xOut) THEN
    // разрешено не меньше требуемого и все запрошенные пущены (или пуск шага не подтвердился за
    // STN_SEQ_START_TIMEOUT) — последовательность завершена. Только «разрешено не меньше требуемого» мало:
    // после Restart автоматика набирает потребность заново, и в конце задержки она ещё не полная (PMI-34)
    xSeq := FALSE;
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.RestartDone, rValue := UINT_TO_REAL(MIN(uiStep, uiRequired)));
    END_IF
END_IF

// 4. Выходы
xPowerLost := xLost;
xRestart := xDelay OR xSeq;
IF xLost OR xDelay THEN
    uiRequestLimit := 0;
ELSIF xSeq THEN
    uiRequestLimit := uiStep;
ELSE
    uiRequestLimit := GVL_Const.STN_PUMP_COUNT;
END_IF

// остаток до следующего шага в целых секундах вверх (HMI, 04 §13.2)
tRemain := T#0S;
IF xDelay THEN
    tRemain := fbDelay.tRemaining;
ELSIF xSeq AND xConfirmed THEN
    tRemain := fbStepWait.tRemaining;
ELSIF xSeq THEN
    tRemain := fbStepTimeout.tRemaining;
END_IF
udiRemain := TIME_TO_UDINT(tRemain) / GVL_Const.STN_MS_PER_S;
IF udiRemain * GVL_Const.STN_MS_PER_S < TIME_TO_UDINT(tRemain) THEN
    udiRemain := udiRemain + 1;
END_IF
uiSeqRemain_s := UDINT_TO_UINT(MIN(udiRemain, UINT_TO_UDINT(PL.GVL_Const.UINT_MAX)));
xFirstCall := FALSE;
