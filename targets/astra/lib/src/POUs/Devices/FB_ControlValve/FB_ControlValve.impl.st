// 0. Первый вызов: число слотов тревог и тип устройства (до ProcessMode)
IF xFirstCall THEN
    uiAlarmCount := GVL_Const.CV_ALARM_COUNT;
    eDevType := E_DeviceType.ControlValve;
END_IF

// 1. Время
BeginCycle();
lrDt_s := F_LTimeToSec(ltIn := ltDt);

// 2. Конфигурация (LKG)
IF AcceptCfg(wErr := CheckConfig(stCfgIn := stCfg)) THEN
    stCfgLkg := stCfg;
END_IF

// 3. Reset: снимает зафиксированное рассогласование и первопричину. Причина рассогласования —
//    расхождение выхода и ОС за время tDev: после Reset она оценивается заново, с начала отсчёта
xResetNow := xResetReq OR stCmd.stCommon.xReset;
IF xResetNow THEN
    xDevLatched := FALSE;
    uiFirstOut := GVL_Const.NO_FIRST_OUT;
    fbDev.Preset(xValue := FALSE);
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF

// 4. Режим: регулирующий клапан не «движется» как механизм — вывод из работы всегда допустим
eRes := ProcessMode(xLocalSel := xLocal, xLocalSupported := TRUE, xOosAllowed := TRUE,
                    stCmd := stCmd.stCommon, stRetain := stRetain);
IF eRes <> E_CmdResult.None THEN
    SetCmdResult(eResult := eRes);
END_IF

// 5. Команд-импульсов у клапана нет: задание Manual — значение stCmd.rPosSpMan_pct

// 6. Логика по stCfgLkg
xRemote := eMode = E_DeviceMode.Auto OR eMode = E_DeviceMode.Manual;
wIlk := wInterlock AND stCfgLkg.wInterlockMask;
xIlkAct := xRemote AND wIlk <> 0;
// 6.1 Первопричина: при переходе слова блокировок из 0 в не 0 — номер младшего взведённого бита
IF wIlkPrev = 0 AND wIlk <> 0 AND eMode <> E_DeviceMode.OutOfService THEN
    wBit := 1;
    uiBit := 0;
    WHILE (wIlk AND wBit) = 0 DO
        wBit := SHL(wBit, 1);
        uiBit := uiBit + 1;
    END_WHILE
    uiFirstOut := uiBit;
END_IF
wIlkPrev := wIlk;

// 6.2 ОС положения и позиционер
xFbOk := stCfgLkg.xFbUsed AND xPosFbValid AND F_IsFinite(rIn := rPosFb_pct);
xFbInvalid := stCfgLkg.xFbUsed AND NOT xFbOk;
xPosFault := xPositionerFault AND eMode <> E_DeviceMode.OutOfService;

// 6.3 Рассогласование: выход прошлого вызова против ОС этого (ОС отражает уже поданное задание);
//     только в Auto/Manual, при достоверной ОС, не во время рампы и не в первом вызове (выхода ещё не было)
xDevCond := xFbOk AND xRemote AND NOT xRampingPrev AND NOT xFirstCall
            AND ABS(rOut_pct - rPosFb_pct) > stCfgLkg.rDevMax_pct;
fbDev(xIn := xDevCond, tOnDelay := stCfgLkg.tDev, itfTime := itfTimeAct);
IF fbDev.xOut AND stCfgLkg.xDevIsFault THEN
    xDevLatched := TRUE;
END_IF
xDevWarn := fbDev.xOut AND NOT stCfgLkg.xDevIsFault;
xFaultAny := xDevLatched OR xPosFault;

// 6.4 Выбор выхода по старшинству (метод SelectOutput)
SelectOutput(rManSp_pct := stCmd.rPosSpMan_pct, rCfgSafePos_pct := stCfg.rSafePos_pct);

// 6.5 Плотное закрытие с гистерезисом (CV-13): включается ниже rTightShut_pct, снимается при положении не ниже
//     rTightShut_pct + CV_TIGHT_HYST_PCT (не выше rOutMax_pct) — задание, шумящее у порога, не «стучит» клапаном о
//     седло. Затем мА с инверсией (без корректной Cfg — инверсия из поданной Cfg)
rTightOff := MIN(stCfgLkg.rTightShut_pct + GVL_Const.CV_TIGHT_HYST_PCT, stCfgLkg.rOutMax_pct);
IF stCfgLkg.rTightShut_pct <= 0.0 THEN
    xTightAct := FALSE;
ELSIF lrRamp_pct < REAL_TO_LREAL(stCfgLkg.rTightShut_pct) THEN
    xTightAct := TRUE;
ELSIF lrRamp_pct >= REAL_TO_LREAL(rTightOff) THEN
    xTightAct := FALSE;
END_IF
IF xTightAct THEN
    rOut_pct := 0.0;
ELSE
    rOut_pct := LREAL_TO_REAL(lrRamp_pct);
END_IF
IF xCfgEverOk THEN
    xInvert := stCfgLkg.xOutInvert;
ELSE
    xInvert := stCfg.xOutInvert;
END_IF
IF xInvert THEN
    rOut_mA := GVL_Const.MA_ZERO + GVL_Const.MA_SPAN * (GVL_Const.PCT_FULL - rOut_pct) / GVL_Const.PCT_FULL;
ELSE
    rOut_mA := GVL_Const.MA_ZERO + GVL_Const.MA_SPAN * rOut_pct / GVL_Const.PCT_FULL;
END_IF

// 6.6 Слежение: пока выходом управляет не оператор, задание Manual = текущий выход
xManualCtl := xCfgEverOk AND eMode = E_DeviceMode.Manual AND NOT xIlkAct AND NOT xFaultAny;
IF NOT xManualCtl THEN
    stCmd.rPosSpMan_pct := rOut_pct;
END_IF
xRampingPrev := xRamping;

// 7. Тревоги (слоты E_CvAlarm)
axAlmCond[E_CvAlarm.Deviation] := xDevWarn OR xDevLatched;
axAlmCond[E_CvAlarm.FbFailure] := xFbInvalid;
axAlmCond[E_CvAlarm.PositionerFault] := xPosFault;
axAlmCond[E_CvAlarm.InterlockAct] := xIlkAct;
arAlmValue[E_CvAlarm.Deviation] := SEL(xFbOk, 0.0, rOut_pct - rPosFb_pct);
arAlmValue[E_CvAlarm.FbFailure] := rPosFb_pct;
arAlmValue[E_CvAlarm.PositionerFault] := rOut_pct;
arAlmValue[E_CvAlarm.InterlockAct] := rOut_pct;
RunAlarms(udiIdBase := stCfgLkg.udiAlarmIdBase, stCmd := stCmd.stCommon, astCfg := stCfgLkg.astAlarm);

// 8. Состояние
xAtSp := xFbOk AND ABS(rOut_pct - rPosFb_pct) <= stCfgLkg.rDevMax_pct;
wFltBits := SEL(xDevLatched, 0, GVL_Const.CV_FLT_DEVIATION) OR SEL(xPosFault, 0, GVL_Const.CV_FLT_POSITIONER);
wWrnBits := SEL(xDevWarn, 0, GVL_Const.CV_WRN_DEVIATION)
            OR SEL(xFbInvalid, 0, GVL_Const.CV_WRN_FB_INVALID)
            OR SEL(xSpInvalid, 0, GVL_Const.CV_WRN_SP_INVALID);
xAvailDev := eMode = E_DeviceMode.Auto AND wFltBits = 0 AND wIlk = 0;
xAutoActive := xAvailDev AND xCfgEverOk;
wLowBits := SEL(xAtSp, 0, GVL_Const.CV_STS_AT_SETPOINT)
            OR SEL(xRamping, 0, GVL_Const.CV_STS_RAMPING)
            OR SEL(xLimMin, 0, GVL_Const.CV_STS_LIMITED_MIN)
            OR SEL(xLimMax, 0, GVL_Const.CV_STS_LIMITED_MAX)
            OR SEL(xIlkAct, 0, GVL_Const.CV_STS_INTERLOCKED)
            OR SEL(xTightAct, 0, GVL_Const.CV_STS_TIGHT_SHUT)
            OR SEL(xSafe, 0, GVL_Const.CV_STS_SAFE_POS)
            OR SEL(xAutoActive, 0, GVL_Const.CV_STS_AVAILABLE);
IF wFltBits <> 0 THEN
    eDevSt := E_Ne107Status.Failure;
ELSIF xDevWarn THEN
    eDevSt := E_Ne107Status.OutOfSpecification;
ELSIF xFbInvalid THEN
    eDevSt := E_Ne107Status.MaintenanceRequired;
ELSE
    eDevSt := E_Ne107Status.Good;
END_IF
stSts.rPosSp_pct := rSpAct;
stSts.rOut_pct := rOut_pct;
stSts.rOut_mA := rOut_mA;
// ОС в Sts — конечная (NaN из Modbus — 0.0, R6); достоверность — в битах
stSts.rPosFb_pct := SEL(F_IsFinite(rIn := rPosFb_pct), 0.0, rPosFb_pct);
IF xFbOk THEN
    stSts.rDeviation_pct := rOut_pct - rPosFb_pct;
ELSE
    stSts.rDeviation_pct := 0.0;
END_IF
stSts.wInterlock := wIlk;
stSts.uiFirstOut := uiFirstOut;
FinishCycle(eDevStatus := eDevSt, xAvailableDev := xAvailDev, wLow := wLowBits, wFaultBits := wFltBits,
            wWarnBits := wWrnBits, stCommon := stSts.stCommon);
