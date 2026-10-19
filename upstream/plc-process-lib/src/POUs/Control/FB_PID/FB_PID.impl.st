// 0. Первый вызов: число слотов тревог и тип устройства (до ProcessMode)
IF xFirstCall THEN
    uiAlarmCount := GVL_Const.PID_ALARM_COUNT;
    eDevType := E_DeviceType.Pid;
END_IF

// 1. Время
BeginCycle();

// 2. Конфигурация (LKG); достоверность PV
IF AcceptCfg(wErr := CheckConfig(stCfgIn := stCfg)) THEN
    stCfgLkg := stCfg;
END_IF
xPvOk := xPvValid AND F_IsFinite(rIn := rPv_eu);
// 2а. Старт ПЛК: выход — фактический выход механизма: rOutAct_pct при xUseOutAct, иначе
//     rTrack_pct при слежении, иначе stCmd.rManualOut_pct. Интегратор инициализирует шаг
//     инициализации первого расчёта (I := u - P)
IF xFirstCall THEN
    IF stCfgLkg.xUseOutAct AND F_IsFinite(rIn := rOutAct_pct) THEN
        lrOut_pct := REAL_TO_LREAL(rOutAct_pct);
    ELSIF xTrack AND F_IsFinite(rIn := rTrack_pct) THEN
        lrOut_pct := REAL_TO_LREAL(rTrack_pct);
    ELSIF F_IsFinite(rIn := stCmd.rManualOut_pct) THEN
        lrOut_pct := REAL_TO_LREAL(stCmd.rManualOut_pct);
    END_IF
END_IF

// 3. Reset: фиксируемых отказов у ПИД нет — команда принимается (тревоги квитирует RunAlarms)
IF xResetReq OR stCmd.stCommon.xReset THEN
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF

// 4. Режим. Запрос Auto без корректной Cfg (RejectedCfg) или при негодной PV (RejectedFault)
//    снимается до ProcessMode. Если в том же вызове есть старший запрос (Manual, OutOfService),
//    Auto снимается молча: ProcessMode обработает старший как одну команду
xAutoReq := stCmd.stCommon.xSetAuto OR (xModeReq AND eModeReq = E_DeviceMode.Auto);
xHigherReq := stCmd.stCommon.xSetOos OR stCmd.stCommon.xSetManual
              OR (xModeReq AND eModeReq <> E_DeviceMode.Auto);
IF xAutoReq AND (NOT xCfgEverOk OR NOT xPvOk) THEN
    IF NOT xHigherReq THEN
        IF NOT xCfgEverOk THEN
            SetCmdResult(eResult := E_CmdResult.RejectedCfg);
        ELSE
            SetCmdResult(eResult := E_CmdResult.RejectedFault);
        END_IF
    END_IF
    stCmd.stCommon.xSetAuto := FALSE;
    IF eModeReq = E_DeviceMode.Auto THEN
        xModeReq := FALSE;
    END_IF
END_IF
eRes := ProcessMode(xLocalSel := FALSE, xLocalSupported := FALSE, xOosAllowed := TRUE,
                    stCmd := stCmd.stCommon, stRetain := stRetain);
IF eRes <> E_CmdResult.None THEN
    SetCmdResult(eResult := eRes);
END_IF

// 5. Переходы логики: PV негодна в Auto без слежения и реакция ShedToManual — в Manual с
//    текущим выходом (stCmd.rManualOut_pct уже равен выходу: слежение в Auto). Признак
//    сброса держит тревогу PvInvalid в Manual, пока PV негодна; снимают его годная PV и
//    выбор оператором OutOfService (docs/fb/FB_PID.md, P-15)
IF xCfgEverOk AND eMode = E_DeviceMode.Auto AND NOT xPvOk AND NOT xTrack
   AND stCfgLkg.ePvFailAction = E_PidPvFailAction.ShedToManual
THEN
    SwitchRemoteMode(eNew := E_DeviceMode.Manual, stRetain := stRetain);
    xPvShed := TRUE;
END_IF
IF xPvOk OR eMode <> E_DeviceMode.Manual THEN
    xPvShed := FALSE;
END_IF

// 6. Логика по stCfgLkg
// 6.1 Задание: цель (внешнее, PV при слежении задания в Manual или операторское), пределы.
//     Неконечная цель — прежняя цель и предупреждение; пределы действуют и на неё (NaN с
//     первого вызова, смена пределов при NaN; P-16). Внешнее задание и PV пишутся в
//     stCmd.rSp_eu: переход на операторское задание без рывка
xSpTrack := eMode = E_DeviceMode.Manual AND stCfgLkg.xSpTrackPv AND NOT xSpExt AND xPvOk;
IF xSpExt THEN
    rSpRaw_eu := rSpExt_eu;
ELSIF xSpTrack THEN
    rSpRaw_eu := rPv_eu;
ELSE
    rSpRaw_eu := stCmd.rSp_eu;
END_IF
xSpInvalid := NOT F_IsFinite(rIn := rSpRaw_eu);
IF NOT xSpInvalid THEN
    lrSpTarget_eu := REAL_TO_LREAL(rSpRaw_eu);
    IF xCfgEverOk AND (xSpExt OR xSpTrack) THEN
        stCmd.rSp_eu := rSpRaw_eu;
    END_IF
END_IF
lrSpTarget_eu := LIMIT(REAL_TO_LREAL(stCfgLkg.rSpMin_eu), lrSpTarget_eu, REAL_TO_LREAL(stCfgLkg.rSpMax_eu));

// 6.2 Нужен ли расчёт. Без корректной Cfg и при негодной PV расчёта нет, следующий — шаг
//     инициализации; в OutOfService расчёта нет (выход из OOS ставит инициализацию в хуке).
//     LTIME без знака: «время назад» проверяется до вычитания. Разрыв больше tDtMax и «время
//     назад» — шаг инициализации с битом DT_GAP; dt = 0 — расчёта нет
xCalc := FALSE;
xInitStep := FALSE;
xDtGap := FALSE;
lrDt_s := 0.0;
IF NOT xCfgEverOk OR NOT xPvOk THEN
    xCalcInit := TRUE;
ELSIF eMode <> E_DeviceMode.OutOfService THEN
    IF xCalcInit OR ltNow < ltLastCalc THEN
        xCalc := TRUE;
        xInitStep := TRUE;
        xDtGap := xFirstCalc OR NOT xCalcInit;
    ELSE
        ltElapsed := ltNow - ltLastCalc;
        IF ltElapsed > TIME_TO_LTIME(stCfgLkg.tDtMax) THEN
            xCalc := TRUE;
            xInitStep := TRUE;
            xDtGap := TRUE;
        ELSIF ltElapsed > LTIME#0S AND ltElapsed >= TIME_TO_LTIME(stCfgLkg.tSample) THEN
            xCalc := TRUE;
            lrDt_s := F_LTimeToSec(ltIn := ltElapsed);
        END_IF
    END_IF
END_IF

// 6.3 Шаг расчёта (контракт 17.4): рампа задания, ошибка, зона нечувствительности, P, D, v
IF xCalc THEN
    ltLastCalc := ltNow;
    xCalcInit := FALSE;
    xFirstCalc := FALSE;
    lrDtCalc_s := lrDt_s;
    CalcStep(xInit := xInitStep, lrStep_s := lrDt_s, xSpFollow := xSpTrack);
END_IF

// 6.4 Выход по старшинству (контракт 2.6, 17.5), интегратор, rOut_pct, xSatHigh, xSatLow
SelectOutput(xCalcNow := xCalc, xInit := xInitStep, lrStep_s := lrDt_s, rManualOut_pct := stCmd.rManualOut_pct);

// 6.5 Слежение в Cmd: в Auto, OutOfService и при слежении выход пишется в rManualOut_pct
IF xCfgEverOk AND (eMode <> E_DeviceMode.Manual OR xTrackAct) THEN
    stCmd.rManualOut_pct := LREAL_TO_REAL(lrOut_pct);
END_IF

// 7. Тревоги: слот 0 PvInvalid — PV негодна в Auto или после сброса в Manual по отказу PV
axAlmCond[E_PidAlarm.PvInvalid] := NOT xPvOk AND (eMode = E_DeviceMode.Auto OR xPvShed);
axAlmSuppress[E_PidAlarm.PvInvalid] := FALSE;
arAlmValue[E_PidAlarm.PvInvalid] := SEL(F_IsFinite(rIn := rPv_eu), 0.0, rPv_eu);
RunAlarms(udiIdBase := stCfgLkg.udiAlarmIdBase, stCmd := stCmd.stCommon, astCfg := stCfgLkg.astAlarm);

// 8. Состояние
xPvFault := NOT xPvOk AND eMode = E_DeviceMode.Auto AND NOT xTrack;
IF xPvFault THEN
    eDevSt := E_Ne107Status.Failure;
ELSE
    eDevSt := E_Ne107Status.Good;
END_IF
stSts.rSpTarget_eu := LREAL_TO_REAL(lrSpTarget_eu);
stSts.rSp_eu := LREAL_TO_REAL(lrSp_eu);
stSts.rPv_eu := SEL(F_IsFinite(rIn := rPv_eu), 0.0, rPv_eu);   // NaN из Modbus — 0.0 (R6), PV_FAIL в битах
stSts.rErr_pct := LREAL_TO_REAL(lrErr_pct);
stSts.rOut_pct := rOut_pct;
stSts.rP_pct := LREAL_TO_REAL(lrP_pct);
stSts.rI_pct := LREAL_TO_REAL(lrI_pct);
stSts.rD_pct := LREAL_TO_REAL(lrD_pct);
stSts.rDt_ms := LREAL_TO_REAL(lrDtCalc_s * GVL_Const.MS_PER_S);
FinishCycle(eDevStatus := eDevSt,
            xAvailableDev := eMode = E_DeviceMode.Auto AND xPvOk AND NOT xTrack,
            wLow := SEL(xSatHigh, 0, GVL_Const.PID_STS_SAT_HIGH)
                    OR SEL(xSatLow, 0, GVL_Const.PID_STS_SAT_LOW)
                    OR SEL(xCfgEverOk AND NOT xSpInit AND eMode <> E_DeviceMode.OutOfService
                           AND lrSp_eu <> lrSpTarget_eu, 0, GVL_Const.PID_STS_SP_RAMPING)
                    OR SEL(xInDeadband, 0, GVL_Const.PID_STS_IN_DEADBAND)
                    OR SEL(xPvOk, GVL_Const.PID_STS_PV_FAIL, 0)            // бит при PV негодна
                    OR SEL(xDtGap, 0, GVL_Const.PID_STS_DT_GAP)
                    OR SEL(xTrackAct, 0, GVL_Const.PID_STS_TRACKING)
                    OR SEL(xOutRateLim, 0, GVL_Const.PID_STS_OUT_RATE_LIMITED),
            wFaultBits := SEL(xPvFault, 0, GVL_Const.PID_FLT_PV_INVALID),
            wWarnBits := SEL(xDtGap, 0, GVL_Const.PID_WRN_DT_GAP) OR SEL(xSpInvalid, 0, GVL_Const.PID_WRN_SP_INVALID),
            stCommon := stSts.stCommon);
