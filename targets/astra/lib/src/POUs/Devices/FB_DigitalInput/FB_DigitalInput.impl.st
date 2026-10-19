// 0. Первый вызов (до ProcessMode): тип, число слотов тревог; режим «Измерение» в памяти режима,
//    подмена (Manual) даёт CheckFunction
IF xFirstCall THEN
    uiAlarmCount := GVL_Const.DI_ALARM_COUNT;
    eDevType := E_DeviceType.DigitalInput;
    xManualIsCheck := TRUE;
    stModeMem.eRemoteMode := E_DeviceMode.Auto;
END_IF

// 1. Время
BeginCycle();

// 2. Конфигурация (LKG): дальше логика читает только stCfgLkg
IF AcceptCfg(wErr := CheckConfig(stCfgIn := stCfg)) THEN
    stCfgLkg := stCfg;
END_IF

// 3. Reset: фиксируемых отказов нет (отказ канала снимается сам), результат команды — Accepted;
//    квитирование выполнит RunAlarms
IF xResetReq OR stCmd.stCommon.xReset THEN
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF

// 4. Режим: Local нет, OutOfService разрешён всегда; память режима — stModeMem (A-06)
eRes := ProcessMode(xLocalSel := FALSE, xLocalSupported := FALSE, xOosAllowed := TRUE,
                    stCmd := stCmd.stCommon, stRetain := stModeMem);
IF eRes <> E_CmdResult.None THEN
    SetCmdResult(eResult := eRes);
END_IF

// 5. Подмена ограничена по времени: Manual длится tSubstMax — возврат в Auto (SubstExpired), как у AI.
//    Preset — чтобы новый запрос подмены в следующем вызове отсчитал tSubstMax заново
fbSubst(xIn := (eMode = E_DeviceMode.Manual) AND (stCfgLkg.tSubstMax > T#0S), tOnDelay := stCfgLkg.tSubstMax,
        itfTime := itfTimeAct);
IF fbSubst.xOut THEN
    SwitchRemoteMode(eNew := E_DeviceMode.Auto, stRetain := stModeMem);
    fbSubst.Preset(xValue := FALSE);
    SetCmdResult(eResult := E_CmdResult.SubstExpired);
END_IF

// 6. Сигнал: инверсия до задержек. При отказе канала сигнал не верен: задержки стоят на значении отказа
//    (HoldLast — значение до отказа, ForceFalse/ForceTrue — значение по eFailValue) и после возврата канала
//    отсчитываются от него заново: значение отказа снимается только через задержку, без провала защитного
//    сигнала (DI-2). В первом вызове с корректной Cfg значение берётся без задержки (DI-1): не в первом вызове
//    вообще — до корректной Cfg инверсия взята из умолчаний, и НЗ-контакт прошёл бы через задержку с неверной
//    полярностью
xRaw := xIn XOR stCfgLkg.xInvert;
IF xDelayInit AND xCfgEverOk THEN
    xGood := xRaw AND NOT xChannelFault;
    fbDebounce.Preset(xValue := xGood);
    xDelayInit := FALSE;
END_IF
IF xChannelFault THEN
    // значение отказа: HoldLast — прежнее, ForceTrue — TRUE, ForceFalse — FALSE (eFailValue проверен CheckConfig)
    xGood := (xGood AND stCfgLkg.eFailValue = E_DiFailValue.HoldLast) OR stCfgLkg.eFailValue = E_DiFailValue.ForceTrue;
    fbDebounce.Preset(xValue := xGood);
ELSE
    fbDebounce(xIn := xRaw, tOnDelay := stCfgLkg.tOnDelay, tOffDelay := stCfgLkg.tOffDelay, itfTime := itfTimeAct);
    xGood := fbDebounce.xOut;
END_IF

// Выбор значения по режиму и состоянию канала
xFaultAct := xChannelFault AND eMode <> E_DeviceMode.OutOfService;
SelectValue(xSubst := stCmd.xSubstValue);

// Слежение: пока значением управляет не оператор, ФБ пишет текущее значение в поле подмены —
// переход в подмену без рывка
IF eMode <> E_DeviceMode.Manual THEN
    stCmd.xSubstValue := xValue;
END_IF

// 7. Тревоги (слоты E_DiAlarm): State подавляется при отказе канала — отказ показывает слот Failure
//    (без дублирования по ISA-18.2). Значение события — xValue как 0.0 / 1.0
xAlmCond := xValue = stCfgLkg.xAlarmOnTrue;
rAlmValue := SEL(xValue, 0.0, 1.0);
axAlmCond[E_DiAlarm.State] := xAlmCond;
axAlmCond[E_DiAlarm.Failure] := xChannelFault;
axAlmSuppress[E_DiAlarm.State] := xChannelFault;
axAlmSuppress[E_DiAlarm.Failure] := FALSE;
arAlmValue[E_DiAlarm.State] := rAlmValue;
arAlmValue[E_DiAlarm.Failure] := rAlmValue;
RunAlarms(udiIdBase := stCfgLkg.udiAlarmIdBase, stCmd := stCmd.stCommon, astCfg := stCfgLkg.astAlarm);

// 8. Состояние; биты отсчёта задержек — пока канал исправен
wLowBits := SEL(xValue, 0, GVL_Const.DI_STS_VALUE) OR SEL(xRaw, 0, GVL_Const.DI_STS_RAW)
            OR SEL(fbDebounce.xTimingOn AND NOT xChannelFault, 0, GVL_Const.DI_STS_TIMING_ON)
            OR SEL(fbDebounce.xTimingOff AND NOT xChannelFault, 0, GVL_Const.DI_STS_TIMING_OFF)
            OR SEL(xChannelFault, 0, GVL_Const.DI_STS_CHANNEL_FAULT)
            OR SEL(xAlmCond, 0, GVL_Const.DI_STS_ALARM_COND);
IF xFaultAct THEN
    eDevSt := E_Ne107Status.Failure;
ELSE
    eDevSt := E_Ne107Status.Good;
END_IF
stSts.uiSubstRemain_s := SubstRemainSec();
FinishCycle(eDevStatus := eDevSt, xAvailableDev := xValid, wLow := wLowBits,
            wFaultBits := SEL(xFaultAct, 0, GVL_Const.DI_FLT_CHANNEL), wWarnBits := 0,
            stCommon := stSts.stCommon);
