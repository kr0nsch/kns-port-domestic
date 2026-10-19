// 0. Время модели: шаг от прошлого вызова, не больше SIM_DT_MAX; «время назад» — шаг 0
itfTimeAct := itfTime;
IF itfTimeAct = 0 THEN
    itfTimeAct := fbSysTime;
END_IF
ltNow := itfTimeAct.Now();
IF NOT xInit THEN
    xInit := TRUE;
    ltLast := ltNow;
    lrClock_h := REAL_TO_LREAL(TodOf(lrHours := REAL_TO_LREAL(stCfg.rStartTimeOfDay_h)));
    fbTank.SetLevel(rNewLevel_m := stCfg.rLevelInit_m);
    stFaultPrev := stFault;             // начальные инъекции — не изменение
    rTT403Hold := stCfg.rAirTemp_C;
END_IF
IF ltNow >= ltLast THEN
    ltDt := ltNow - ltLast;
ELSE
    ltDt := LTIME#0S;
END_IF
ltLast := ltNow;
IF ltDt > GVL_Const.SIM_DT_MAX THEN
    ltDt := GVL_Const.SIM_DT_MAX;       // пауза задачи (отладка): модель не догоняет время целиком
END_IF
lrDt_s := PL.F_LTimeToSec(ltIn := ltDt);

// 1. Команды модели; импульсы сбрасываются после выполнения
IF stCmd.xClearFaults THEN
    stFault := stFaultNone;
    stCmd.xClearFaults := FALSE;
END_IF
IF stCmd.xResetPlant THEN
    // исходное состояние проверки (И0): уровень, время перелива, ливни, ПЧ
    fbTank.SetLevel(rNewLevel_m := stCfg.rLevelInit_m);
    fbTank.ClearOverflow();
    fbStorms.Clear(lrFrom_h := lrClock_h);
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        afbVfd[uiPump].ResetDrive();
    END_FOR
    stCmd.xResetPlant := FALSE;
END_IF
IF stCmd.xSetLevel THEN
    fbTank.SetLevel(rNewLevel_m := stCmd.rSetLevel_m);
    stCmd.xSetLevel := FALSE;
END_IF
IF stCmd.xSetTimeOfDay THEN
    IF PL.F_IsFinite(rIn := stCmd.rTimeOfDay_h) THEN
        // те же сутки, новое время; ливни, которые уже шли, сняты (скачок времени)
        lrClock_h := UDINT_TO_LREAL(DayOf(lrHours := lrClock_h)) * REAL_TO_LREAL(GVL_Const.SIM_HOURS_PER_DAY)
                     + REAL_TO_LREAL(TodOf(lrHours := REAL_TO_LREAL(stCmd.rTimeOfDay_h)));
        fbStorms.Clear(lrFrom_h := lrClock_h);
    END_IF
    stCmd.xSetTimeOfDay := FALSE;
END_IF
IF stCmd.xStormNow THEN
    IF NOT stCmd.xInflowOverride THEN
        fbStorms.StartNow(lrStartAt_h := lrClock_h, rPeak_m3h := stCmd.rStormPeak_m3h,
                          tDuration := stCmd.tStormDuration);
    END_IF
    stCmd.xStormNow := FALSE;
END_IF
IF stCmd.xPressReset THEN
    xHs501Pressed := TRUE;
    stCmd.xPressReset := FALSE;
END_IF
IF stCmd.xPressSilence THEN
    xHs502Pressed := TRUE;
    stCmd.xPressSilence := FALSE;
END_IF

// 2. ПЧ: частота этого вызова; ток в регистр — по гидравлике прошлого вызова
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    afbVfd[uiPump](xRunCmd := axRun[uiPump], wCtw := awCtw[uiPump], uiFref := auiFref[uiPump],
                   xPowerOk := NOT stFault.xPowerLoss, xFaultInj := stFault.axVfdFault[uiPump],
                   xOverheat := stFault.axOverheat[uiPump], xCommLoss := stFault.axVfdCommLoss[uiPump],
                   xLocal := stFault.axLocal[uiPump], xLocalRun := stFault.axLocalRun[uiPump],
                   xNoFeedback := stFault.axNoFeedback[uiPump], xFeedbackStuck := stFault.axFeedbackStuck[uiPump],
                   rMotorCurrent_A := fbHydraulic.arCurrent_A[uiPump], tAccel := stCfg.tVfdAccel,
                   tBoot := stCfg.tVfdBoot, itfTime := itfTimeAct);
    arSpeed[uiPump] := afbVfd[uiPump].rFreq_Hz / GVL_Const.VFD_FREQ_NOM_HZ;
END_FOR

// 3. Подшаги не длиннее SIM_DT_SUBSTEP: часы, приток, рабочая точка, резервуар (явный Эйлер).
//    Шаг 0 (первый вызов, «время назад») — один подшаг нулевой длины: выходы без изменения уровня
uiSubsteps := ULINT_TO_UINT((LTIME_TO_ULINT(ltDt) + LTIME_TO_ULINT(GVL_Const.SIM_DT_SUBSTEP) - 1)
                            / LTIME_TO_ULINT(GVL_Const.SIM_DT_SUBSTEP));
IF uiSubsteps = 0 THEN
    uiSubsteps := 1;
END_IF
lrSub_s := lrDt_s / UINT_TO_LREAL(uiSubsteps);
FOR uiSub := 1 TO uiSubsteps DO
    lrClock_h := lrClock_h + lrSub_s / REAL_TO_LREAL(GVL_Const.SIM_S_PER_H);
    lrSimTime_s := lrSimTime_s + lrSub_s;
    rTod_h := TodOf(lrHours := lrClock_h);
    fbStorms(lrClock_h := lrClock_h, udiSeed := stCfg.udiSeed, uiStormsPerDayMax := stCfg.uiStormsPerDayMax,
             rPeakMin_m3h := stCfg.rStormPeakMin_m3h, rPeakMax_m3h := stCfg.rStormPeakMax_m3h,
             tDurationMin := stCfg.tStormMin, tDurationMax := stCfg.tStormMax);
    fbInflow(rTimeOfDay_h := rTod_h, rAverage_m3h := stCfg.rInflowAvg_m3h, arProfile := stCfg.arDailyProfile);
    IF stCmd.xInflowOverride THEN
        IF PL.F_IsFinite(rIn := stCmd.rInflowOverride_m3h) THEN
            rInflow_m3h := MAX(stCmd.rInflowOverride_m3h, 0.0);
        ELSE
            rInflow_m3h := 0.0;
        END_IF
    ELSE
        rInflow_m3h := fbInflow.rInflow_m3h + fbStorms.rInflow_m3h;
    END_IF
    // приёмок осушен — по уровню LREAL резервуара: гидравлика и баланс объёма решают одинаково
    fbHydraulic(arSpeed := arSpeed, axAirLock := stFault.axAirLock, axClog := stFault.axClog,
                rLevel_m := fbTank.rLevel_m, xIntakeDry := fbTank.xIntakeDry, stPump := stCfg.stPump);
    fbTank(rInflow_m3h := rInflow_m3h, rOutflow_m3h := fbHydraulic.rFlow_m3h, lrDt_s := lrSub_s,
           rArea_m2 := stCfg.rTankArea_m2, rOverflow_m := stCfg.rLevelOverflow_m);
END_FOR

// 4. Датчики 4–20 мА с инъекциями (индексы SIM_AI_*; газы — значение инъекции или фон)
arAiValue[GVL_Const.SIM_AI_LT101] := fbTank.rLevel_m;
arAiValue[GVL_Const.SIM_AI_PT201] := fbHydraulic.rPressure_bar;
arAiValue[GVL_Const.SIM_AI_FT202] := fbHydraulic.rFlow_m3h;
IF stFault.rH2S_mgm3 < 0.0 THEN
    arAiValue[GVL_Const.SIM_AI_AT401] := stCfg.rH2SBase_mgm3;
ELSE
    arAiValue[GVL_Const.SIM_AI_AT401] := stFault.rH2S_mgm3;
END_IF
IF stFault.rCh4_pctLel < 0.0 THEN
    arAiValue[GVL_Const.SIM_AI_AT402] := stCfg.rCh4Base_pctLel;
ELSE
    arAiValue[GVL_Const.SIM_AI_AT402] := stFault.rCh4_pctLel;
END_IF
arAiRange[GVL_Const.SIM_AI_LT101] := GVL_Const.SIM_LT101_RANGE_M;
arAiRange[GVL_Const.SIM_AI_PT201] := GVL_Const.SIM_PT201_RANGE_BAR;
arAiRange[GVL_Const.SIM_AI_FT202] := GVL_Const.SIM_FT202_RANGE_M3H;
arAiRange[GVL_Const.SIM_AI_AT401] := GVL_Const.SIM_AT401_RANGE_MGM3;
arAiRange[GVL_Const.SIM_AI_AT402] := GVL_Const.SIM_AT402_RANGE_PCTLEL;
FOR uiAi := 1 TO GVL_Const.SIM_AI_COUNT DO
    afbAi[uiAi](rValue := arAiValue[uiAi], rRangeLo := 0.0, rRangeHi := arAiRange[uiAi],
                eFault := stFault.aeAiFault[uiAi], rForced_mA := stFault.arAiForced_mA[uiAi]);
END_FOR
stIo.rLT101_mA := afbAi[GVL_Const.SIM_AI_LT101].rCurrent_mA;
stIo.rPT201_mA := afbAi[GVL_Const.SIM_AI_PT201].rCurrent_mA;
stIo.rFT202_mA := afbAi[GVL_Const.SIM_AI_FT202].rCurrent_mA;
stIo.rAT401_mA := afbAi[GVL_Const.SIM_AI_AT401].rCurrent_mA;
stIo.rAT402_mA := afbAi[GVL_Const.SIM_AI_AT402].rCurrent_mA;

// 5. TT403 по RS485-2: без ответа регистр замирает
IF NOT stFault.xTempCommLoss THEN
    rTT403Hold := stCfg.rAirTemp_C;
END_IF
stIo.rTT403 := rTT403Hold;
stIo.xMbOk_RS485_2_S10 := NOT stFault.xTempCommLoss;

// 6. Контакты шкафа и павильона (поплавки НЗ: TRUE — норма)
stIo.xLS102 := F_FloatContact(rLevel_m := fbTank.rLevel_m, rMark_m := GVL_Const.STN_LS102_MARK_M, xHighFloat := TRUE,
                              eStuck := stFault.eLs102Stuck);
stIo.xLS103 := F_FloatContact(rLevel_m := fbTank.rLevel_m, rMark_m := GVL_Const.STN_LS103_MARK_M, xHighFloat := FALSE,
                              eStuck := stFault.eLs103Stuck);
stIo.xLS203 := stFault.xValveChamberFlood;
stIo.xES301 := NOT stFault.xPowerLoss;
stIo.xYS302 := stFault.xPowerLoss;
stIo.xYS303 := stFault.xUpsFault;
stIo.xZS404 := stCmd.xDoorOpen;
stIo.xYS405 := stFault.xFire;
// кнопки: нажатие длится SIM_BUTTON_PULSE
fbHs501(xIn := xHs501Pressed, tOnDelay := GVL_Const.SIM_BUTTON_PULSE, itfTime := itfTimeAct);
IF fbHs501.xOut THEN
    xHs501Pressed := FALSE;
END_IF
stIo.xHS501 := xHs501Pressed;
fbHs502(xIn := xHs502Pressed, tOnDelay := GVL_Const.SIM_BUTTON_PULSE, itfTime := itfTimeAct);
IF fbHs502.xOut THEN
    xHs502Pressed := FALSE;
END_IF
stIo.xHS502 := xHs502Pressed;
// В1: блок-контакт пускателя следует команде через SIM_V1_FB_DELAY (катушка — от силовой сети)
fbV1Fb(xIn := xV1Run AND NOT stFault.xPowerLoss, tOnDelay := GVL_Const.SIM_V1_FB_DELAY,
       tOffDelay := GVL_Const.SIM_V1_FB_DELAY, itfTime := itfTimeAct);
stIo.xV1_RFB := fbV1Fb.xOut AND NOT stFault.xFanNoFeedback;
stIo.xV1_FLT := stFault.xFanFault;

// 7. Насосы: реле ПЧ, переключатель, реле защиты, регистры и обмен (имена GVL_IO у каждого насоса свои)
stIo.xP101_RFB := afbVfd[1].xRelayRun;
stIo.xP101_FLT := afbVfd[1].xRelayFault;
stIo.xHS114 := stFault.axLocal[1];
stIo.xTS112 := NOT stFault.axOverheat[1];
stIo.xMS113 := stFault.axLeak[1];
stIo.wP101_STW := afbVfd[1].wStw;
stIo.uiP101_FACT := afbVfd[1].uiFact;
stIo.uiIT111 := afbVfd[1].uiCurrent;
stIo.uiP101_FCODE := afbVfd[1].uiFcode;
stIo.xMbOk_RS485_1_S1 := afbVfd[1].xCommOk;

stIo.xP102_RFB := afbVfd[2].xRelayRun;
stIo.xP102_FLT := afbVfd[2].xRelayFault;
stIo.xHS124 := stFault.axLocal[2];
stIo.xTS122 := NOT stFault.axOverheat[2];
stIo.xMS123 := stFault.axLeak[2];
stIo.wP102_STW := afbVfd[2].wStw;
stIo.uiP102_FACT := afbVfd[2].uiFact;
stIo.uiIT121 := afbVfd[2].uiCurrent;
stIo.uiP102_FCODE := afbVfd[2].uiFcode;
stIo.xMbOk_RS485_1_S2 := afbVfd[2].xCommOk;

stIo.xP103_RFB := afbVfd[3].xRelayRun;
stIo.xP103_FLT := afbVfd[3].xRelayFault;
stIo.xHS134 := stFault.axLocal[3];
stIo.xTS132 := NOT stFault.axOverheat[3];
stIo.xMS133 := stFault.axLeak[3];
stIo.wP103_STW := afbVfd[3].wStw;
stIo.uiP103_FACT := afbVfd[3].uiFact;
stIo.uiIT131 := afbVfd[3].uiCurrent;
stIo.uiP103_FCODE := afbVfd[3].uiFcode;
stIo.xMbOk_RS485_1_S3 := afbVfd[3].xCommOk;

// 8. Изменения инъекций: счётчик для события журнала 101021 (журнал пишет PRG_Station в MainTask)
IF NOT F_FaultInjEqual(stA := stFault, stB := stFaultPrev) THEN
    udiFaultSeq := udiFaultSeq + 1;
    stFaultPrev := stFault;
END_IF

// 9. Состояние модели
stSts.rLevel_m := fbTank.rLevel_m;
stSts.rInflow_m3h := rInflow_m3h;
stSts.rOutflow_m3h := fbHydraulic.rFlow_m3h;
stSts.rHead_m := fbHydraulic.rHead_m;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    stSts.arPumpFlow_m3h[uiPump] := fbHydraulic.arFlow_m3h[uiPump];
    stSts.arFreq_Hz[uiPump] := afbVfd[uiPump].rFreq_Hz;
    stSts.arCurrent_A[uiPump] := fbHydraulic.arCurrent_A[uiPump];
END_FOR
stSts.rTimeOfDay_h := TodOf(lrHours := lrClock_h);
stSts.udiDay := DayOf(lrHours := lrClock_h);
stSts.xStormActive := fbStorms.xActive AND NOT stCmd.xInflowOverride;
IF stCmd.xInflowOverride THEN
    stSts.rStormInflow_m3h := 0.0;
ELSE
    stSts.rStormInflow_m3h := fbStorms.rInflow_m3h;
END_IF
stSts.udiOverflow_s := fbTank.udiOverflow_s;
stSts.rTimeScaleAct := rTimeScaleAct;
stSts.lrSimTime_s := lrSimTime_s;
stSts.xRunning := TRUE;
stSts.udiFaultSeq := udiFaultSeq;
