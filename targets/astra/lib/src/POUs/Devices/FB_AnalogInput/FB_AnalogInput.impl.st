// 0. Первый вызов (до ProcessMode): тип, число слотов тревог; режим «Измерение» в памяти режима,
//    подмена (Manual) даёт CheckFunction
IF xFirstCall THEN
    uiAlarmCount := GVL_Const.AI_ALARM_COUNT;
    eDevType := E_DeviceType.AnalogInput;
    xManualIsCheck := TRUE;
    stModeMem.eRemoteMode := E_DeviceMode.Auto;
END_IF

// 1. Время
BeginCycle();

// 2. Конфигурация (LKG): дальше логика читает только stCfgLkg
IF AcceptCfg(wErr := CheckConfig(stCfgIn := stCfg)) THEN
    stCfgLkg := stCfg;
END_IF

// 3. Reset: фиксируемых отказов нет (отказ сигнала снимается сам), результат команды — Accepted;
//    квитирование выполнит RunAlarms
IF xResetReq OR stCmd.stCommon.xReset THEN
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF

// 4. Режим: Local нет, OutOfService разрешён всегда; память режима — stModeMem (подмена и вывод из
//    работы не переживают перезапуск ПЛК, A-06)
eRes := ProcessMode(xLocalSel := FALSE, xLocalSupported := FALSE, xOosAllowed := TRUE,
                    stCmd := stCmd.stCommon, stRetain := stModeMem);
IF eRes <> E_CmdResult.None THEN
    SetCmdResult(eResult := eRes);
END_IF

// 5. Подмена ограничена по времени: Manual длится tSubstMax — возврат в Auto (SubstExpired). До выбора
//    значения: в этом же вызове значение уже измеренное. Preset — чтобы новый запрос подмены в
//    следующем вызове отсчитал tSubstMax заново
fbSubst(xIn := (eMode = E_DeviceMode.Manual) AND (stCfgLkg.tSubstMax > T#0S), tOnDelay := stCfgLkg.tSubstMax,
        itfTime := itfTimeAct);
IF fbSubst.xOut THEN
    SwitchRemoteMode(eNew := E_DeviceMode.Auto, stRetain := stModeMem);
    fbSubst.Preset(xValue := FALSE);
    SetCmdResult(eResult := E_CmdResult.SubstExpired);
END_IF

// 6. Сигнал и значение
// 6.1 Классификация (мгновенная, NE 43)
eSignal := ClassifySignal();
xRawFail := eSignal = E_AiSignalState.NotFinite OR eSignal = E_AiSignalState.ChannelFault
            OR eSignal = E_AiSignalState.FailLow OR eSignal = E_AiSignalState.FailHigh;
xRawOor := eSignal = E_AiSignalState.UnderRange OR eSignal = E_AiSignalState.OverRange;
// 6.2 Подтверждение: и появление, и возврат — через tFailDelay. Без корректной Cfg (тип входа ещё не
//     известен) и в OutOfService сигнал не контролируется: флаги снимаются сразу, отсчёт — заново.
//     Последнее хорошее значение при этом устаревает (датчик могли сменить «в ремонте»): после возврата
//     контроля удерживать нечего, как после старта ПЛК (AI-2)
xSupervise := xCfgEverOk AND eMode <> E_DeviceMode.OutOfService;
IF xSupervise THEN
    fbFail(xIn := xRawFail, tOnDelay := stCfgLkg.tFailDelay, tOffDelay := stCfgLkg.tFailDelay,
           itfTime := itfTimeAct);
    fbOor(xIn := xRawOor AND NOT xRawFail, tOnDelay := stCfgLkg.tFailDelay, tOffDelay := stCfgLkg.tFailDelay,
          itfTime := itfTimeAct);
ELSE
    fbFail.Preset(xValue := FALSE);
    fbOor.Preset(xValue := FALSE);
    xHaveGood := FALSE;
END_IF
xFail := fbFail.xOut;
xOor := fbOor.xOut;
// 6.3 Значение и фильтр: не считаются без корректной Cfg, в OutOfService и пока сигнал отказал. Фильтр
//     начинается заново после подтверждённого отказа и после возврата контроля; короткий провал его только
//     замораживает (AI-12)
ComputeValue(xCompute := xSupervise AND NOT xRawFail, xRestart := xFail OR NOT xSupervise);
// 6.4 Выбор значения по режиму и состоянию сигнала
xValueBad := xFail OR (xRawFail AND NOT xHaveGood);
SelectValue(rSubst_eu := stCmd.rSubstValue_eu);

// 7. Уставки — по выбранному значению (в Manual — по подменённому: так при наладке проверяют
//    блокировки). Флаги снимаются сразу в OutOfService, без корректной Cfg и в Auto без измеренного
//    значения, если не xLimitsOnFail
xLimOff := eMode = E_DeviceMode.OutOfService OR NOT xCfgEverOk
           OR (eMode = E_DeviceMode.Auto AND xValueBad AND NOT stCfgLkg.xLimitsOnFail);
xHH := CallLimit(rLimValue := rValue_eu, xHigh := TRUE, xOff := xLimOff,
                 stLimCfg := stCfgLkg.astLimit[E_AiAlarm.HH], fbLimit := afbLimit[E_AiAlarm.HH]);
xH := CallLimit(rLimValue := rValue_eu, xHigh := TRUE, xOff := xLimOff,
                stLimCfg := stCfgLkg.astLimit[E_AiAlarm.H], fbLimit := afbLimit[E_AiAlarm.H]);
xL := CallLimit(rLimValue := rValue_eu, xHigh := FALSE, xOff := xLimOff,
                stLimCfg := stCfgLkg.astLimit[E_AiAlarm.L], fbLimit := afbLimit[E_AiAlarm.L]);
xLL := CallLimit(rLimValue := rValue_eu, xHigh := FALSE, xOff := xLimOff,
                 stLimCfg := stCfgLkg.astLimit[E_AiAlarm.LL], fbLimit := afbLimit[E_AiAlarm.LL]);

// 8. Слежение: пока значением управляет не оператор, ФБ пишет текущее значение в поле подмены —
//    переход в подмену без рывка
IF eMode <> E_DeviceMode.Manual THEN
    stCmd.rSubstValue_eu := rValue_eu;
END_IF

// 9. Тревоги (слоты E_AiAlarm). Значение события: rValue_eu, у слота Failure — сырое rIn
xLimSupp := xSuppressLimitAlarms OR (xFail AND NOT stCfgLkg.xLimitsOnFail);
axAlmCond[E_AiAlarm.HH] := xHH;
axAlmCond[E_AiAlarm.H] := xH;
axAlmCond[E_AiAlarm.L] := xL;
axAlmCond[E_AiAlarm.LL] := xLL;
axAlmCond[E_AiAlarm.Failure] := xFail;
axAlmCond[E_AiAlarm.OutOfRange] := xOor AND NOT xFail;
axAlmSuppress[E_AiAlarm.HH] := xLimSupp;
axAlmSuppress[E_AiAlarm.H] := xLimSupp;
axAlmSuppress[E_AiAlarm.L] := xLimSupp;
axAlmSuppress[E_AiAlarm.LL] := xLimSupp;
axAlmSuppress[E_AiAlarm.Failure] := FALSE;
axAlmSuppress[E_AiAlarm.OutOfRange] := FALSE;
arAlmValue[E_AiAlarm.HH] := rValue_eu;
arAlmValue[E_AiAlarm.H] := rValue_eu;
arAlmValue[E_AiAlarm.L] := rValue_eu;
arAlmValue[E_AiAlarm.LL] := rValue_eu;
arAlmValue[E_AiAlarm.Failure] := rIn;
arAlmValue[E_AiAlarm.OutOfRange] := rValue_eu;
RunAlarms(udiIdBase := stCfgLkg.udiAlarmIdBase, stCmd := stCmd.stCommon, astCfg := stCfgLkg.astAlarm);

// 10. Состояние. AI_STS_FAIL_PENDING — в Auto последнее хорошее значение удерживается как годное до
//     подтверждения отказа (не при xValueBad: удерживать нечего, AI-2)
wLowBits := SEL(xHH, 0, GVL_Const.AI_STS_HH) OR SEL(xH, 0, GVL_Const.AI_STS_H)
            OR SEL(xL, 0, GVL_Const.AI_STS_L) OR SEL(xLL, 0, GVL_Const.AI_STS_LL)
            OR SEL(xFail, 0, GVL_Const.AI_STS_SIGNAL_FAIL) OR SEL(xOor, 0, GVL_Const.AI_STS_OUT_OF_RANGE)
            OR SEL(eMode = E_DeviceMode.Auto AND xSupervise AND xRawFail AND NOT xValueBad, 0,
                   GVL_Const.AI_STS_FAIL_PENDING)
            OR SEL(xLowCut, 0, GVL_Const.AI_STS_LOW_CUT);
IF xFail THEN
    eDevSt := E_Ne107Status.Failure;
ELSIF xOor THEN
    eDevSt := E_Ne107Status.OutOfSpecification;
ELSE
    eDevSt := E_Ne107Status.Good;
END_IF
stSts.rValue_eu := rValue_eu;
stSts.rValue_pct := rValue_pct;
stSts.rIn := rIn;
stSts.eSignal := eSignal;
stSts.uiSubstRemain_s := SubstRemainSec();
FinishCycle(eDevStatus := eDevSt, xAvailableDev := xValid, wLow := wLowBits, wFaultBits := FaultBits(),
            wWarnBits := WarningBits(), stCommon := stSts.stCommon);
