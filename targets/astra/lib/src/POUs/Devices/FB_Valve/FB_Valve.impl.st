// 0. Первый вызов: число слотов тревог и тип устройства (до ProcessMode)
IF xFirstCall THEN
    uiAlarmCount := GVL_Const.VLV_ALARM_COUNT;
    eDevType := E_DeviceType.Valve;
END_IF

// 1. Время
BeginCycle();

// 2. Конфигурация (LKG)
IF AcceptCfg(wErr := CheckConfig(stCfgIn := stCfg)) THEN
    stCfgLkg := stCfg;
END_IF
// сигналы по LKG: концевик учитывается, только если подключён; муфта — только у Motorized
xMotorized := stCfgLkg.eType = E_ValveType.Motorized;
xAtOpen := stCfgLkg.xZsoUsed AND xZso;
xAtClose := stCfgLkg.xZscUsed AND xZsc;
xTrqOpen := xMotorized AND stCfgLkg.xTorqueUsed AND xTorqueOpen;
xTrqClose := xMotorized AND stCfgLkg.xTorqueUsed AND xTorqueClose;

// 3. Reset (метод ResetFaults; бит xReset сбрасывает RunAlarms в шаге 7)
ResetFaults(xRequest := xResetReq OR stCmd.stCommon.xReset);

// 4. Режим: вывод из работы — только когда арматура не движется
eRes := ProcessMode(xLocalSel := xLocal, xLocalSupported := TRUE,
                    xOosAllowed := eState <> E_ValveState.Opening AND eState <> E_ValveState.Closing
                                   AND eState <> E_ValveState.Reversing AND NOT xSafeMove,
                    stCmd := stCmd.stCommon, stRetain := stRetain);
IF eRes <> E_CmdResult.None THEN
    SetCmdResult(eResult := eRes);
END_IF

// 5. Условия вызова для шагов-методов; команды устройства (метод HandleCommands)
xRemote := eMode = E_DeviceMode.Auto OR eMode = E_DeviceMode.Manual;
wIlk := wInterlock AND stCfgLkg.wInterlockMask;
xIlkAct := xRemote AND wIlk <> 0;
wPermMissOpen := stCfgLkg.wPermitOpenMask AND NOT wPermitOpen;
wPermMissClose := stCfgLkg.wPermitCloseMask AND NOT wPermitClose;
xFaultAny := xFltFailOpen OR xFltFailClose OR xFltPosLost OR xFltTorque OR xFltExt OR xBothLimits;
HandleCommands(stValveCmd := stCmd, stValveRet := stRetain);

// 6. Логика по stCfgLkg: цель, контроль концевиков, состояние, движение, выходы, счётчики
SelectTarget();
SuperviseLimits();
TrackPosition();
DriveToTarget();
RunTravelTimers();
SafeMoveOnFault();
SetOutputs();
CountOperations(stValveRet := stRetain);

// 7. Тревоги (слоты E_ValveAlarm)
axAlmCond[E_ValveAlarm.FailToOpen] := xFltFailOpen;
axAlmCond[E_ValveAlarm.FailToClose] := xFltFailClose;
axAlmCond[E_ValveAlarm.BothLimits] := xBothLimits;
axAlmCond[E_ValveAlarm.PositionLost] := xFltPosLost;
axAlmCond[E_ValveAlarm.TorqueTrip] := xFltTorque;
axAlmCond[E_ValveAlarm.ExtFault] := xFltExt;
axAlmCond[E_ValveAlarm.InterlockAct] := xIlkAct;
RunAlarms(udiIdBase := stCfgLkg.udiAlarmIdBase, stCmd := stCmd.stCommon, astCfg := stCfgLkg.astAlarm);

// 8. Состояние
IF xRemote AND NOT xIlkAct AND eTarget = E_ValveState.Open AND eState <> E_ValveState.Open THEN
    wPermMiss := wPermMissOpen;
ELSIF xRemote AND NOT xIlkAct AND eTarget = E_ValveState.Closed AND eState <> E_ValveState.Closed THEN
    wPermMiss := wPermMissClose;
ELSE
    wPermMiss := 0;
END_IF
IF eState = E_ValveState.Opening OR eState = E_ValveState.Closing OR xSafeMove THEN
    // остаток до таймаута хода (аварийного хода), целые секунды вверх, не больше UINT_MAX
    IF xSafeMove THEN
        lrRemain_s := F_TimeToSec(tIn := fbSafeMove.tRemaining);
    ELSE
        lrRemain_s := F_TimeToSec(tIn := fbTravel.tRemaining);
    END_IF
    udiRemain_s := LREAL_TO_UDINT(lrRemain_s);
    IF UDINT_TO_LREAL(udiRemain_s) < lrRemain_s THEN
        udiRemain_s := udiRemain_s + 1;
    END_IF
    stSts.uiTravelRemain_s := UDINT_TO_UINT(MIN(udiRemain_s, UINT_TO_UDINT(GVL_Const.UINT_MAX)));
ELSE
    stSts.uiTravelRemain_s := 0;
END_IF
xMaint := stCfgLkg.udiMaintCycles > 0 AND stRetain.udiOpCountMaint >= stCfgLkg.udiMaintCycles;
wFltBits := SEL(xFltFailOpen, 0, GVL_Const.VLV_FLT_FAIL_TO_OPEN)
            OR SEL(xFltFailClose, 0, GVL_Const.VLV_FLT_FAIL_TO_CLOSE)
            OR SEL(xBothLimits, 0, GVL_Const.VLV_FLT_BOTH_LIMITS)
            OR SEL(xFltPosLost, 0, GVL_Const.VLV_FLT_POSITION_LOST)
            OR SEL(xFltTorque, 0, GVL_Const.VLV_FLT_TORQUE_TRIP)
            OR SEL(xFltExt, 0, GVL_Const.VLV_FLT_EXT_FAULT);
wWrnBits := SEL(xMaint, 0, GVL_Const.VLV_WRN_MAINT_CYCLES)
            OR SEL(xPowerOk, GVL_Const.VLV_WRN_POWER_LOST, 0)
            OR SEL(eMode = E_DeviceMode.Local AND wIlk <> 0, 0, GVL_Const.VLV_WRN_INTERLOCK_IN_LOCAL)
            OR SEL((eState = E_ValveState.Open AND NOT stCfgLkg.xZsoUsed)
                   OR (eState = E_ValveState.Closed AND NOT stCfgLkg.xZscUsed AND NOT stCfgLkg.xCloseOnTorque),
                   0, GVL_Const.VLV_WRN_POSITION_BY_TIME)
            OR SEL(eState = E_ValveState.Unknown, 0, GVL_Const.VLV_WRN_POSITION_UNKNOWN);
xAvailDev := eMode = E_DeviceMode.Auto AND wFltBits = 0 AND wIlk = 0 AND xPowerOk;
wLowBits := SEL(xOpened, 0, GVL_Const.VLV_STS_OPENED)
            OR SEL(xClosed, 0, GVL_Const.VLV_STS_CLOSED)
            OR SEL(eState = E_ValveState.Opening OR (xSafeMove AND eSafeDir = E_ValveState.Opening), 0,
                   GVL_Const.VLV_STS_OPENING)
            OR SEL(eState = E_ValveState.Closing OR (xSafeMove AND eSafeDir = E_ValveState.Closing), 0,
                   GVL_Const.VLV_STS_CLOSING)
            OR SEL(xIlkAct, 0, GVL_Const.VLV_STS_INTERLOCKED)
            OR SEL(wPermMiss <> 0, 0, GVL_Const.VLV_STS_PERMIT_MISSING)
            OR SEL(xTrqOpen OR xTrqClose, 0, GVL_Const.VLV_STS_TORQUE)
            OR SEL(xAvailDev AND xCfgEverOk, 0, GVL_Const.VLV_STS_AVAILABLE);
IF wFltBits <> 0 THEN
    eDevSt := E_Ne107Status.Failure;
ELSIF xMaint THEN
    eDevSt := E_Ne107Status.MaintenanceRequired;
ELSE
    eDevSt := E_Ne107Status.Good;
END_IF
stSts.eState := eState;
stSts.wInterlock := wIlk;
stSts.wPermitMissing := wPermMiss;
stSts.uiFirstOut := uiFirstOut;
stSts.wReserve := 0;
stSts.udiCycles := stRetain.udiOpCount;
stSts.udiCyclesMaint := stRetain.udiOpCountMaint;
stSts.rActTime_h := LREAL_TO_REAL(UDINT_TO_LREAL(stRetain.udiOpTime_s) / UDINT_TO_LREAL(GVL_Const.S_PER_H));
FinishCycle(eDevStatus := eDevSt, xAvailableDev := xAvailDev, wLow := wLowBits, wFaultBits := wFltBits,
            wWarnBits := wWrnBits, stCommon := stSts.stCommon);
