// 0. Старт приложения (событие 101015) — первой записью станции
IF xFirstCall AND itfEvents <> 0 THEN
    itfEvents.LogEvent(eEvent := E_StationEvent.PlcStart, rValue := 0.0);
END_IF
uiCmdCount := 0;
eCmdRes := stSts.eCmdResult;

// 1. Уставки (DESIGN 7, шаг 2; 04 §18.3). «Применить уставки проекта» и откат командой переписывают
//    записанные уставки; корректные уставки становятся действующей копией (LKG), каждое принятое
//    изменение — событие 101017 (номер параметра; команда — значение 0). Копия LKG сохраняется в
//    энергонезависимой памяти (stCfgLkgRetain): при старте ПЛК действующая копия — сохранённая, если она
//    корректна, иначе уставки проекта; неверная правка, оставленная до перезапуска, не возвращает станцию
//    к уставкам проекта
IF xFirstCall THEN
    IF F_StationCfgCheck(stCfg := stCfgLkgRetain, stPidCfg := stLIC101Cfg, rLvlL_m := rLvlL_m,
                         rLvlH_m := rLvlH_m) = 0 THEN
        stCfgLkg := stCfgLkgRetain;
    ELSE
        stCfgLkg := GVL_StationDefaults.stStationCfg;
        stCfgLkgRetain := stCfgLkg;
    END_IF
END_IF
xCfgCmd := FALSE;
IF xApplyProjectCfg THEN
    stCfgPersist := GVL_StationDefaults.stStationCfg;
    stLIC101Cfg := GVL_StationDefaults.stLIC101Cfg;
    xCfgCmd := TRUE;
END_IF
IF stCmd.xRevertCfg THEN
    stCfgPersist := stCfgLkg;
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := PL.E_CmdResult.Accepted;
    xCfgCmd := TRUE;
    stCmd.xRevertCfg := FALSE;
END_IF
IF xCfgCmd AND itfEvents <> 0 THEN
    itfEvents.LogEvent(eEvent := E_StationEvent.CfgChanged, rValue := 0.0);
END_IF
wCfgErr := F_StationCfgCheck(stCfg := stCfgPersist, stPidCfg := stLIC101Cfg, rLvlL_m := rLvlL_m, rLvlH_m := rLvlH_m);
IF wCfgErr = 0 THEN
    uiParam := ChangedParam(stOld := stCfgLkg, stNew := stCfgPersist);
    IF uiParam <> 0 THEN
        stCfgLkg := stCfgPersist;
        stCfgLkgRetain := stCfgPersist;                 // энергонезависимая копия — только при изменении
        // при старте записанные уставки принимаются молча; команда уже записала событие
        IF NOT xFirstCall AND NOT xCfgCmd AND itfEvents <> 0 THEN
            itfEvents.LogEvent(eEvent := E_StationEvent.CfgChanged, rValue := UINT_TO_REAL(uiParam));
        END_IF
    END_IF
END_IF

// 2. Команды станции и кнопки шкафа (DESIGN 7, шаг 3) — по порядку контракта 2.1: сброс,
//    квитирование, режим и способ, маски тревог, номера, звук, выгрузка
xResetNow := (xResetButton AND NOT xResetBtnPrev) OR stCmd.xResetAll;
IF xResetButton AND NOT xResetBtnPrev AND itfEvents <> 0 THEN
    itfEvents.LogEvent(eEvent := E_StationEvent.ResetAll, rValue := GVL_Const.STN_EVT_SRC_BUTTON);
END_IF
IF stCmd.xResetAll THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := PL.E_CmdResult.Accepted;
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.ResetAll, rValue := GVL_Const.STN_EVT_SRC_HMI);
    END_IF
END_IF
IF xResetNow THEN
    fbLIC101.Reset();                                   // устройства — PRG_Station по xResetAllReq
END_IF
xResetAllReq := xResetNow;

xAckNow := stCmd.xAckAll;
IF xAckNow THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := PL.E_CmdResult.Accepted;
    fbLIC101.AckAll();
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.AckAll, rValue := 0.0);
    END_IF
END_IF
xAckAllReq := xAckNow;

fbMode(xSetAuto := stCmd.xSetAuto, xSetManual := stCmd.xSetManual, xSetStepped := stCmd.xSetStepped,
       xSetLevelPid := stCmd.xSetLevelPid, aitfPump := aitfPump, itfEvents := itfEvents, stRetain := stRetain);
IF fbMode.uiCmdCount > 0 THEN
    uiCmdCount := uiCmdCount + fbMode.uiCmdCount;
    eCmdRes := fbMode.eCmdResult;
END_IF
xManual := fbMode.eMode <> E_StationMode.Auto;

wAckMask := stCmd.wAckReq;
wShelveMask := stCmd.wShelveReq;
wUnshelveMask := stCmd.wUnshelveReq;
IF wAckMask <> 0 THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := PL.E_CmdResult.Accepted;
END_IF
IF wShelveMask <> 0 THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := PL.E_CmdResult.Accepted;
END_IF
IF wUnshelveMask <> 0 THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := PL.E_CmdResult.Accepted;
END_IF

// номера тревог выполняет сводка (PRG_Station вызывает её до ядра): здесь — результат и сброс номера
IF stCmd.udiAckId <> 0 THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := SEL(xAckIdFound, PL.E_CmdResult.RejectedState, PL.E_CmdResult.Accepted);
END_IF
IF stCmd.udiShelveId <> 0 THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := SEL(xShelveIdFound, PL.E_CmdResult.RejectedState, PL.E_CmdResult.Accepted);
END_IF
IF stCmd.udiUnshelveId <> 0 THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := SEL(xUnshelveIdFound, PL.E_CmdResult.RejectedState, PL.E_CmdResult.Accepted);
END_IF

xSilenceNow := (xSilenceButton AND NOT xSilenceBtnPrev) OR stCmd.xSilence;
IF xSilenceButton AND NOT xSilenceBtnPrev AND itfEvents <> 0 THEN
    itfEvents.LogEvent(eEvent := E_StationEvent.Silence, rValue := GVL_Const.STN_EVT_SRC_BUTTON);
END_IF
IF stCmd.xSilence THEN
    uiCmdCount := uiCmdCount + 1;
    eCmdRes := PL.E_CmdResult.Accepted;
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.Silence, rValue := GVL_Const.STN_EVT_SRC_HMI);
    END_IF
END_IF

// выгрузка журнала: пока идёт прежняя (снимок или запись), новая отклоняется
xExportReq := FALSE;
IF stCmd.xExportLog THEN
    uiCmdCount := uiCmdCount + 1;
    IF eLogExport = E_LogExportState.Snapshot OR eLogExport = E_LogExportState.Writing THEN
        eCmdRes := PL.E_CmdResult.RejectedState;
    ELSE
        eCmdRes := PL.E_CmdResult.Accepted;
        xExportReq := TRUE;
    END_IF
END_IF

// импульсы и номера сброшены в том же цикле (04 §19.2)
stCmd.xSetAuto := FALSE;
stCmd.xSetManual := FALSE;
stCmd.xSetStepped := FALSE;
stCmd.xSetLevelPid := FALSE;
stCmd.xAckAll := FALSE;
stCmd.xResetAll := FALSE;
stCmd.xSilence := FALSE;
stCmd.xExportLog := FALSE;
stCmd.wAckReq := 0;
stCmd.wShelveReq := 0;
stCmd.wUnshelveReq := 0;
stCmd.udiAckId := 0;
stCmd.udiShelveId := 0;
stCmd.udiUnshelveId := 0;
xResetBtnPrev := xResetButton;
xSilenceBtnPrev := xSilenceButton;

// 3. Насосы: работающие (в первом вызове устройства ещё не вызывались — по ОС GVL_IO.xP10n_RFB)
uiRunningNow := 0;
xAnyRunning := FALSE;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    axAdoptRun[uiPump] := axRunFeedback[uiPump];
    IF NOT xFirstCall THEN
        axAdoptRun[uiPump] := FALSE;
        IF aitfPump[uiPump] <> 0 THEN
            axAdoptRun[uiPump] := aitfPump[uiPump].Running;
        END_IF
    END_IF
    IF axAdoptRun[uiPump] THEN
        uiRunningNow := uiRunningNow + 1;
        xAnyRunning := TRUE;
    END_IF
END_FOR

// 4. Питание (требуемое число — прошлого цикла), защиты, защиты насосов (DESIGN 7, шаг 5)
fbPower(xPowerOk := xPowerOk, uiRequired := uiRequiredPrev, uiRunningRequested := fbRotation.uiRunningRequested,
        itfTime := itfTime, itfEvents := itfEvents, stCfg := stCfgLkg);
fbProt(rLevel_m := rLevel_m, xLevelValid := xLevelValid, eLevelNe107 := eLevelNe107, xLevelL := xLevelL,
       xLevelLL := xLevelLL, xLevelH := xLevelH, xLevelHH := xLevelHH, xFloatHigh := xFloatHigh,
       xFloatDry := xFloatDry, uiRunning := uiRunningNow, itfTime := itfTime, itfEvents := itfEvents,
       stCfg := stCfgLkg);
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF aitfPump[uiPump] <> 0 THEN
        afbPumpProt[uiPump](xRunning := aitfPump[uiPump].Running, rSpeedAct_pct := aitfPump[uiPump].SpeedAct,
                            rCurrent_A := arCurrent_A[uiPump], xCurrentValid := axCurrentValid[uiPump],
                            xOverheat := axOverheat[uiPump], xReset := axPumpReset[uiPump] OR xResetNow,
                            itfTime := itfTime, stCfg := stCfgLkg);
    ELSE
        afbPumpProt[uiPump](xRunning := FALSE, rSpeedAct_pct := 0.0, rCurrent_A := arCurrent_A[uiPump],
                            xCurrentValid := FALSE, xOverheat := axOverheat[uiPump],
                            xReset := axPumpReset[uiPump] OR xResetNow, itfTime := itfTime, stCfg := stCfgLkg);
    END_IF
    axTrip[uiPump] := afbPumpProt[uiPump].xUnderloadTrip;
    // АВР — по отказу устройства или блокировке станции насоса: недогрузка и перегрев. TS1n2 без задержки приходит
    // раньше аварии ПЧ (фильтр tExtFaultFilter): насос останавливается и теряет запрос до отказа (04 §9.1, PMI-16)
    axAtsTrip[uiPump] := afbPumpProt[uiPump].wInterlock <> 0;
END_FOR

// 5. Действующее управление (готовность ПИД — прошлого цикла); смена управления или вход в
//    «Автомат» — вход без рывка: число насосов по работающим, роли — работающим (шаг 6)
fbSelect(eMode := fbMode.eMode, eMethod := fbMode.eMethod, xPowerLost := fbPower.xPowerLost,
         xRestart := fbPower.xRestart, xDryRun := fbProt.xDryRun, xFloatMode := fbProt.xFloatMode,
         xEmergency := fbProt.xEmergency, xPidReady := fbPidCtl.xPidReady);
eAct := fbSelect.eControlAct;
xInitReq := fbSelect.xChanged OR fbMode.xEnteredAuto;
// последовательный пуск идёт по тому же ступенчатому автомату: Restart <-> Stepped — без новой инициализации
xSteppedCont := (eAct = E_ControlAct.Stepped OR eAct = E_ControlAct.Restart)
                AND (eActPrev = E_ControlAct.Stepped OR eActPrev = E_ControlAct.Restart);

// 6. Регуляторы вызываются всегда (таймеры непрерывны); уровень — годный по защитам (LT101 не
//    исключён). Последовательный пуск — по ступенчатому автомату: ПИД в слежении (шаг 7)
fbStepped(xEnable := eAct = E_ControlAct.Stepped OR eAct = E_ControlAct.Restart, rLevel_m := rLevel_m,
          xLevelValid := fbProt.xLevelUsable, xInit := xInitReq AND NOT xSteppedCont, uiInitPumps := uiRunningNow,
          itfTime := itfTime, stCfg := stCfgLkg);
fbPidCtl(xEnable := eAct = E_ControlAct.LevelPid, rLevel_m := rLevel_m, xLevelValid := fbProt.xLevelUsable,
         rPidOut_pct := fbLIC101.rOut_pct, ePidMode := fbLIC101.Mode, aitfPump := aitfPump, axCommOk := axCommOk,
         uiLead := fbRotation.uiLead, xInit := xInitReq, uiInitPumps := uiRunningNow, itfTime := itfTime,
         stCfg := stCfgLkg);
CASE eAct OF
    E_ControlAct.Stepped:
        uiRequired := fbStepped.uiRequired;
    E_ControlAct.Restart:
        // последовательный пуск охватывает все насосы состояния под ним: сухой ход — 0, по поплавкам и аварийный
        // уровень — все (ведущий, подпорный, остальные), иначе ступенчатый автомат; по одному — uiRequestLimit
        IF fbProt.xDryRun THEN
            uiRequired := 0;
        ELSIF fbProt.xFloatMode THEN
            uiRequired := fbProt.uiFloatRequired;
        ELSIF fbProt.xEmergency THEN
            uiRequired := GVL_Const.STN_PUMP_COUNT;
        ELSE
            uiRequired := fbStepped.uiRequired;
        END_IF
    E_ControlAct.LevelPid:
        uiRequired := fbPidCtl.uiRequired;
    E_ControlAct.Emergency:
        uiRequired := GVL_Const.STN_PUMP_COUNT;
    E_ControlAct.Float:
        uiRequired := fbProt.uiFloatRequired;
ELSE
    uiRequired := 0;                                    // DryRunStop, PowerLost, Manual
END_CASE

// 7. Роли и чередование (шаг 8): старт ПЛК — подхват по ОС; АВР (шаг 9)
fbRotation(xEnable := NOT xManual, uiRequired := uiRequired, uiRequestLimit := fbPower.uiRequestLimit,
           xRequireComm := eAct = E_ControlAct.LevelPid,
           xHandoverAllowed := eAct = E_ControlAct.Stepped OR eAct = E_ControlAct.LevelPid,
           xAdopt := xInitReq OR xFirstCall, axAdoptRun := axAdoptRun, aitfPump := aitfPump, axCommOk := axCommOk,
           itfTime := itfTime, itfEvents := itfEvents, stCfg := stCfgLkg, stRetain := stRetain);
fbAts(xEnable := NOT xManual, aitfPump := aitfPump, axRun := fbRotation.axRun, axTrip := axAtsTrip,
      uiRequired := uiRequired, uiAvailable := fbRotation.uiAvailable, uiForeign := fbRotation.uiForeign,
      itfTime := itfTime, itfEvents := itfEvents, stCfg := stCfgLkg);

// 8. LIC101 (шаг 10; 04 §7.1): задание — внешнее из LKG, слежение за ведущим, когда ПИД не управляет
fbLIC101(rPv_eu := rLevel_m, xPvValid := fbProt.xLevelUsable, xSpExt := TRUE, rSpExt_eu := stCfgLkg.rLevelSp_m,
         xTrack := fbPidCtl.xTrack, rTrack_pct := fbPidCtl.rTrack_pct, rOutAct_pct := fbPidCtl.rTrack_pct,
         itfTime := itfTime, stCmd := stLIC101Cmd, stCfg := stLIC101Cfg, stRetain := stLIC101Retain);

// 9. Общее задание частоты (шаг 11). «Ручной» — задание работающего насоса с меньшей наработкой
//    (будущего ведущего): вход в «Автомат» без рывка (04 §3.2); сухой ход и нет напряжения — прежнее
CASE eAct OF
    E_ControlAct.LevelPid:
        rSpeedSp_pct := fbLIC101.rOut_pct;
    E_ControlAct.Stepped:
        rSpeedSp_pct := stCfgLkg.rStepSpeed_pct;
    E_ControlAct.Restart:
        // последовательный пуск при аварийном уровне или по поплавкам — на полной частоте, как сами эти режимы
        IF (fbProt.xFloatMode OR fbProt.xEmergency) AND NOT fbProt.xDryRun THEN
            rSpeedSp_pct := GVL_Const.STN_FULL_SPEED_PCT;
        ELSE
            rSpeedSp_pct := stCfgLkg.rStepSpeed_pct;
        END_IF
    E_ControlAct.Emergency, E_ControlAct.Float:
        rSpeedSp_pct := GVL_Const.STN_FULL_SPEED_PCT;
    E_ControlAct.Manual:
        uiTrack := 0;
        FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
            IF aitfPump[uiPump] <> 0 THEN
                IF aitfPump[uiPump].Running THEN
                    IF uiTrack = 0 THEN
                        uiTrack := uiPump;
                    ELSIF aitfPump[uiPump].RunSeconds < aitfPump[uiTrack].RunSeconds THEN
                        uiTrack := uiPump;
                    END_IF
                END_IF
            END_IF
        END_FOR
        IF uiTrack <> 0 THEN
            rSpeedSp_pct := aitfPump[uiTrack].SpeedRef;
        END_IF
ELSE
    ;                                                   // DryRunStop, PowerLost: запросов нет
END_CASE

// 10. Входы автоматики устройств (шаг 12): запросы, блокировки, подавление тревог коллектора, В1
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    axRun[uiPump] := fbRotation.axRun[uiPump];
    awInterlock[uiPump] := afbPumpProt[uiPump].wInterlock;
    IF fbProt.xDryRun THEN
        awInterlock[uiPump] := awInterlock[uiPump] OR GVL_Const.KNS_ILK_DRY_RUN;
    END_IF
END_FOR
fbFlowSettle(xIn := xAnyRunning, tOnDelay := GVL_Const.STN_FLOW_SETTLE, itfTime := itfTime);
xSuppressFlowAlarms := NOT fbFlowSettle.xOut;
fbVent(xGasHigh := xGasHigh, xDoorOpen := xDoorOpen, xTempHigh := xTempHigh, xFire := xFire, itfTime := itfTime,
       stCfg := stCfgLkg);
xV1Run := fbVent.xRun;
wV1Interlock := fbVent.wInterlock;

// 11. Тревоги KNS1.* (шаг 13; условия и подавления — 04 §15, DESIGN 6.11)
FOR uiSlot := 1 TO GVL_Const.STN_ALARM_COUNT DO
    axCond[uiSlot] := FALSE;
    axSuppress[uiSlot] := FALSE;
    arValue[uiSlot] := 0.0;
END_FOR
axCond[E_StationAlarm.EHL] := fbProt.xEmergency;
axSuppress[E_StationAlarm.EHL] := fbProt.xFloatMode;
arValue[E_StationAlarm.EHL] := rLevel_m;
axCond[E_StationAlarm.DRY] := fbProt.xDryRun;
axSuppress[E_StationAlarm.DRY] := fbProt.xFloatMode;
arValue[E_StationAlarm.DRY] := rLevel_m;
axCond[E_StationAlarm.LACK] := fbAts.xLack;
axSuppress[E_StationAlarm.LACK] := fbPower.xPowerLost OR xManual;
arValue[E_StationAlarm.LACK] := UINT_TO_REAL(uiRequired);
axCond[E_StationAlarm.NORES] := fbAts.xNoReserve;
// сухой ход станции блокирует все насосы: они недоступны по защите, а не из-за отказов (дубль KNS1.DRY)
axSuppress[E_StationAlarm.NORES] := fbAts.xLack OR fbPower.xPowerLost OR xManual OR fbProt.xDryRun;
arValue[E_StationAlarm.NORES] := UINT_TO_REAL(fbRotation.uiAvailable);
axCond[E_StationAlarm.ATS] := fbAts.xAtsActive;
axSuppress[E_StationAlarm.ATS] := fbPower.xPowerLost;
arValue[E_StationAlarm.ATS] := UDINT_TO_REAL(fbAts.udiAtsCount);
axCond[E_StationAlarm.FLOAT] := fbProt.xFloatMode;
axCond[E_StationAlarm.LDEV] := fbProt.xLdev;
arValue[E_StationAlarm.LDEV] := WORD_TO_REAL(fbProt.wLdev);
axCond[E_StationAlarm.STEP] := fbSelect.xStepFallback;
axSuppress[E_StationAlarm.STEP] := eAct = E_ControlAct.Emergency OR eAct = E_ControlAct.Float
                                   OR eAct = E_ControlAct.DryRunStop OR eAct = E_ControlAct.PowerLost;
axCond[E_StationAlarm.NOAUTO] := xManual;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    axCond[E_StationAlarm.UL1 + uiPump - 1] := axTrip[uiPump];
    arValue[E_StationAlarm.UL1 + uiPump - 1] := arCurrent_A[uiPump];
END_FOR
axCond[E_StationAlarm.SIM] := xSimulation;
fbAlarms(axCond := axCond, axSuppress := axSuppress, arValue := arValue, wAckReq := wAckMask,
         wShelveReq := wShelveMask, wUnshelveReq := wUnshelveMask, xAckAll := xAckNow OR xResetNow,
         itfTime := itfTime, stCfg := stCfgLkg);
fbAnnunciator(auiUnack := auiUnack, auiActive := auiActive, udiNewHighSeq := udiNewHighSeq,
              xSilence := xSilenceNow, itfTime := itfTime);
xHorn := fbAnnunciator.xHorn;
xLamp := fbAnnunciator.xLamp;
xK1 := fbAnnunciator.xK1Energized;

// 12. События журнала (шаг 14): выгрузка CSV завершена или с ошибкой; изменена инъекция отказа
IF eLogExport <> eLogExportPrev AND itfEvents <> 0 THEN
    IF eLogExport = E_LogExportState.Done THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.LogExported, rValue := UINT_TO_REAL(uiExportLines));
    ELSIF eLogExport = E_LogExportState.Error THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.LogExportFailed, rValue := UDINT_TO_REAL(udiExportError));
    END_IF
END_IF
eLogExportPrev := eLogExport;
IF NOT xFirstCall AND udiSimFaultSeq <> udiSimSeqPrev AND itfEvents <> 0 THEN
    itfEvents.LogEvent(eEvent := E_StationEvent.SimFaultChanged, rValue := UDINT_TO_REAL(udiSimFaultSeq));
END_IF
udiSimSeqPrev := udiSimFaultSeq;

// 13. Состояние станции (шаг 15; 04 §19.3)
wState := 0;
IF fbProt.xDryRun THEN
    wState := wState OR GVL_Const.STN_ST_DRY_RUN;
END_IF
IF fbProt.xEmergency THEN
    wState := wState OR GVL_Const.STN_ST_EMERGENCY;
END_IF
IF fbProt.xFloatMode THEN
    wState := wState OR GVL_Const.STN_ST_FLOAT;
END_IF
IF axCond[E_StationAlarm.STEP] AND NOT axSuppress[E_StationAlarm.STEP] THEN
    wState := wState OR GVL_Const.STN_ST_STEP_FALLBACK;
END_IF
IF fbPower.xPowerLost THEN
    wState := wState OR GVL_Const.STN_ST_POWER_LOST;
END_IF
IF fbPower.xRestart THEN
    wState := wState OR GVL_Const.STN_ST_RESTART;
END_IF
IF fbAts.xAtsActive THEN
    wState := wState OR GVL_Const.STN_ST_ATS;
END_IF
IF axCond[E_StationAlarm.NORES] AND NOT axSuppress[E_StationAlarm.NORES] THEN
    wState := wState OR GVL_Const.STN_ST_NO_RESERVE;
END_IF
IF axCond[E_StationAlarm.LACK] AND NOT axSuppress[E_StationAlarm.LACK] THEN
    wState := wState OR GVL_Const.STN_ST_LACK;
END_IF
IF fbProt.xLs102Masked THEN
    wState := wState OR GVL_Const.STN_ST_LS102_MASKED;
END_IF
IF fbProt.xLs103Masked THEN
    wState := wState OR GVL_Const.STN_ST_LS103_MASKED;
END_IF
IF xSimulation THEN
    wState := wState OR GVL_Const.STN_ST_SIMULATION;
END_IF
IF xHorn THEN
    wState := wState OR GVL_Const.STN_ST_HORN;
END_IF
IF NOT xK1 THEN
    wState := wState OR GVL_Const.STN_ST_COMMON_ALARM;
END_IF
IF ePrioUnack <> PL.E_AlarmPriority.None THEN
    wState := wState OR GVL_Const.STN_ST_UNACK;
END_IF
IF fbProt.xLtMasked THEN
    wState := wState OR GVL_Const.STN_ST_LT_MASKED;
END_IF

// NE 107 станции: F — LACK; C — «Ручной», имитация, ошибка уставок; S — FLOAT, STEP, LDEV, NORES;
// M — ТО насоса. Тревога учитывается после своей задержки и без подавления по условию
eNe107 := PL.E_Ne107Status.Good;
xMaint := FALSE;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF aitfPump[uiPump] <> 0 THEN
        xMaint := xMaint OR aitfPump[uiPump].Status = PL.E_Ne107Status.MaintenanceRequired;
    END_IF
END_FOR
IF xMaint THEN
    eNe107 := PL.E_Ne107Status.MaintenanceRequired;
END_IF
IF ((fbAlarms.wAlmActive AND SHL(WORD#1, E_StationAlarm.FLOAT - 1)) <> 0 AND NOT axSuppress[E_StationAlarm.FLOAT])
   OR ((fbAlarms.wAlmActive AND SHL(WORD#1, E_StationAlarm.STEP - 1)) <> 0 AND NOT axSuppress[E_StationAlarm.STEP])
   OR ((fbAlarms.wAlmActive AND SHL(WORD#1, E_StationAlarm.LDEV - 1)) <> 0 AND NOT axSuppress[E_StationAlarm.LDEV])
   OR ((fbAlarms.wAlmActive AND SHL(WORD#1, E_StationAlarm.NORES - 1)) <> 0
       AND NOT axSuppress[E_StationAlarm.NORES]) THEN
    eNe107 := PL.F_Ne107Worst(eA := eNe107, eB := PL.E_Ne107Status.OutOfSpecification);
END_IF
IF xManual OR xSimulation OR wCfgErr <> 0 THEN
    eNe107 := PL.F_Ne107Worst(eA := eNe107, eB := PL.E_Ne107Status.CheckFunction);
END_IF
IF (fbAlarms.wAlmActive AND SHL(WORD#1, E_StationAlarm.LACK - 1)) <> 0 AND NOT axSuppress[E_StationAlarm.LACK] THEN
    eNe107 := PL.E_Ne107Status.Failure;
END_IF

stSts.eMode := fbMode.eMode;
stSts.eMethod := fbMode.eMethod;
stSts.eControlAct := eAct;
stSts.eNe107 := eNe107;
stSts.wState := wState;
stSts.wCfgErr := wCfgErr;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    stSts.aeRole[uiPump] := fbRotation.aeRole[uiPump];
END_FOR
stSts.uiPumpsRequired := uiRequired;
stSts.uiPumpsRunning := fbRotation.uiRunning;
stSts.uiPumpsAvailable := fbRotation.uiAvailable;
stSts.uiLeadPump := fbRotation.uiLead;
stSts.uiSeqRemain_s := fbPower.uiSeqRemain_s;
stSts.eCmdResult := eCmdRes;
stSts.uiCmdSeq := stSts.uiCmdSeq + uiCmdCount;     // UINT по кругу (контракт 2.1)
stSts.wAlmActive := fbAlarms.wAlmActive;
stSts.wAlmUnack := fbAlarms.wAlmUnack;
stSts.wAlmShelved := fbAlarms.wAlmShelved;
stSts.ePrioUnack := ePrioUnack;
FOR uiSlot := 1 TO GVL_Const.ALM_PRIO_COUNT DO
    stSts.auiUnack[uiSlot] := auiUnack[uiSlot];
END_FOR
stSts.eLogExport := eLogExport;
stSts.rLevel_m := rLevel_m;
stSts.rLevelSp_m := stCfgLkg.rLevelSp_m;
stSts.rSpeedSp_pct := rSpeedSp_pct;
stSts.udiEventSeq := udiEventSeq;
stSts.udiLogOverwritten := udiLogOverwritten;

uiRequiredPrev := uiRequired;
eActPrev := eAct;
xFirstCall := FALSE;
