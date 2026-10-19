// 0. Входы GVL_IO ещё недействительны (имитация до первого цикла модели, GVL_Sim.xIoReady): станция и устройства
//    не выполняются — первый вызов ядра (подхват по ОС, событие 101015) только по действительным входам
IF NOT GVL_Sim.xIoReady THEN
    RETURN;
END_IF

// 1. Ссылки и приёмник журнала — каждый цикл (L12 контракта): интерфейсы переживают онлайн-изменение
PL.GVL_Lib.itfAlarmSink := GVL_Log.fbEventLog;
GVL_Log.fbEventLog.itfTime := GVL_Time.fbClockMain;
aitfPump[1] := GVL_Devices.fbP101;
aitfPump[2] := GVL_Devices.fbP102;
aitfPump[3] := GVL_Devices.fbP103;

// 2. Номера тревог выполняет сводка (ядро засчитывает команду, пишет результат, сбрасывает номер)
xAckIdFound := FALSE;
xShelveIdFound := FALSE;
xUnshelveIdFound := FALSE;
IF GVL_Station.stStationCmd.udiAckId <> 0 THEN
    xAckIdFound := GVL_Log.fbAlarmSummary.AckById(udiId := GVL_Station.stStationCmd.udiAckId);
END_IF
IF GVL_Station.stStationCmd.udiShelveId <> 0 THEN
    xShelveIdFound := GVL_Log.fbAlarmSummary.ShelveById(udiId := GVL_Station.stStationCmd.udiShelveId, xShelve := TRUE);
END_IF
IF GVL_Station.stStationCmd.udiUnshelveId <> 0 THEN
    xUnshelveIdFound := GVL_Log.fbAlarmSummary.ShelveById(udiId := GVL_Station.stStationCmd.udiUnshelveId,
                                                          xShelve := FALSE);
END_IF

// 3. Входы ядра — выходы устройств прошлого цикла (шаг 4); импульс сброса насоса — до PRG_Devices
fbCore.axCommOk[1] := (GVL_Devices.fbP101.stSts.stCommon.wWarning AND PL.GVL_Const.MOT_WRN_COMM_LOSS) = 0;
fbCore.axCommOk[2] := (GVL_Devices.fbP102.stSts.stCommon.wWarning AND PL.GVL_Const.MOT_WRN_COMM_LOSS) = 0;
fbCore.axCommOk[3] := (GVL_Devices.fbP103.stSts.stCommon.wWarning AND PL.GVL_Const.MOT_WRN_COMM_LOSS) = 0;
fbCore.axRunFeedback[1] := GVL_IO.xP101_RFB;
fbCore.axRunFeedback[2] := GVL_IO.xP102_RFB;
fbCore.axRunFeedback[3] := GVL_IO.xP103_RFB;
fbCore.axPumpReset[1] := GVL_Hmi.stP101Cmd.stCommon.xReset;
fbCore.axPumpReset[2] := GVL_Hmi.stP102Cmd.stCommon.xReset;
fbCore.axPumpReset[3] := GVL_Hmi.stP103Cmd.stCommon.xReset;
fbCore.arCurrent_A[1] := GVL_Devices.fbIT111.rValue_eu;
fbCore.arCurrent_A[2] := GVL_Devices.fbIT121.rValue_eu;
fbCore.arCurrent_A[3] := GVL_Devices.fbIT131.rValue_eu;
fbCore.axCurrentValid[1] := GVL_Devices.fbIT111.xValid;
fbCore.axCurrentValid[2] := GVL_Devices.fbIT121.xValid;
fbCore.axCurrentValid[3] := GVL_Devices.fbIT131.xValid;
fbCore.axOverheat[1] := GVL_Devices.fbTS112.xValue;
fbCore.axOverheat[2] := GVL_Devices.fbTS122.xValue;
fbCore.axOverheat[3] := GVL_Devices.fbTS132.xValue;
FOR uiIdx := 1 TO GVL_Const.ALM_PRIO_COUNT DO
    fbCore.auiUnack[uiIdx] := GVL_Log.fbAlarmSummary.auiUnack[uiIdx];
    fbCore.auiActive[uiIdx] := GVL_Log.fbAlarmSummary.auiActive[uiIdx];
END_FOR
fbCore(itfTime := GVL_Time.fbClockMain, itfEvents := GVL_Log.fbEventLog, aitfPump := aitfPump,
       rLevel_m := GVL_Devices.fbLT101.rValue_eu, xLevelValid := GVL_Devices.fbLT101.xValid,
       eLevelNe107 := GVL_Devices.fbLT101.stSts.stCommon.eNe107, xLevelL := GVL_Devices.fbLT101.xL,
       xLevelLL := GVL_Devices.fbLT101.xLL, xLevelH := GVL_Devices.fbLT101.xH, xLevelHH := GVL_Devices.fbLT101.xHH,
       rLvlL_m := GVL_Persist.stLT101Cfg.astLimit[PL.E_AiAlarm.L].rSetpoint_eu,
       rLvlH_m := GVL_Persist.stLT101Cfg.astLimit[PL.E_AiAlarm.H].rSetpoint_eu,
       xFloatHigh := GVL_Devices.fbLS102.xValue, xFloatDry := GVL_Devices.fbLS103.xValue,
       xPowerOk := GVL_Devices.fbES301.xValue, xResetButton := GVL_Devices.fbHS501.xValue,
       xSilenceButton := GVL_Devices.fbHS502.xValue, xGasHigh := GVL_Devices.fbAT401.xH OR GVL_Devices.fbAT402.xH,
       xDoorOpen := GVL_Devices.fbZS404.xValue, xTempHigh := GVL_Devices.fbTT403.xH,
       xFire := GVL_Devices.fbYS405.xValue, xApplyProjectCfg := GVL_Hmi.xApplyProjectCfg,
       xAckIdFound := xAckIdFound, xShelveIdFound := xShelveIdFound, xUnshelveIdFound := xUnshelveIdFound,
       xSimulation := GVL_Sim.xSimulation, udiSimFaultSeq := GVL_Sim.stSimSts.udiFaultSeq,
       eLogExport := GVL_Log.eExportState, uiExportLines := GVL_Log.uiExportLines,
       udiExportError := GVL_Log.udiExportError, udiEventSeq := GVL_Log.fbEventLog.udiSeqLast,
       udiLogOverwritten := GVL_Log.fbEventLog.udiOverwritten, ePrioUnack := GVL_Log.fbAlarmSummary.ePrioUnack,
       udiNewHighSeq := GVL_Log.fbAlarmSummary.udiNewHighSeq,
       stCmd := GVL_Station.stStationCmd, stCfgPersist := GVL_Persist.stStationCfg, stCfgLkg := GVL_Station.stCfgLkg,
       stCfgLkgRetain := GVL_Persist.stStationCfgLkg,
       stRetain := GVL_Persist.stStationRetain, fbLIC101 := GVL_Station.fbLIC101,
       stLIC101Cmd := GVL_Station.stLIC101Cmd, stLIC101Cfg := GVL_Persist.stLIC101Cfg,
       stLIC101Retain := GVL_Persist.stLIC101Retain, fbAlarms := GVL_Station.fbAlarms);

// 4. Общий сброс и квитирование всех устройств — только из MainTask (R3 контракта); выгрузка журнала
FOR uiIdx := 1 TO GVL_DeviceList.DEVICE_COUNT DO
    itfDevice := GVL_DeviceList.aitfDevice[uiIdx];
    IF itfDevice <> 0 THEN
        IF fbCore.xResetAllReq THEN
            itfDevice.Reset();
        END_IF
        IF fbCore.xAckAllReq THEN
            itfDevice.AckAll();
        END_IF
    END_IF
END_FOR
IF fbCore.xExportReq THEN
    GVL_Log.fbEventLog.TakeSnapshot();
    GVL_Log.xExportReq := TRUE;
END_IF

// 5. Входы автоматики устройств (шаг 12, R5): запросы, блокировки, задание; копии для HMI
GVL_Devices.fbP101.xAutoRun := fbCore.axRun[1];
GVL_Devices.fbP101.wInterlock := fbCore.awInterlock[1];
GVL_Devices.fbP101.rSpeedSpAuto_pct := fbCore.rSpeedSp_pct;
GVL_Devices.fbP102.xAutoRun := fbCore.axRun[2];
GVL_Devices.fbP102.wInterlock := fbCore.awInterlock[2];
GVL_Devices.fbP102.rSpeedSpAuto_pct := fbCore.rSpeedSp_pct;
GVL_Devices.fbP103.xAutoRun := fbCore.axRun[3];
GVL_Devices.fbP103.wInterlock := fbCore.awInterlock[3];
GVL_Devices.fbP103.rSpeedSpAuto_pct := fbCore.rSpeedSp_pct;
FOR uiIdx := 1 TO GVL_Const.STN_PUMP_COUNT DO
    GVL_Station.axPumpRun[uiIdx] := fbCore.axRun[uiIdx];
    GVL_Station.awPumpInterlock[uiIdx] := fbCore.awInterlock[uiIdx];
END_FOR
GVL_Station.rSpeedSp_pct := fbCore.rSpeedSp_pct;
GVL_Devices.fbPT201.xSuppressLimitAlarms := fbCore.xSuppressFlowAlarms;
GVL_Devices.fbFT202.xSuppressLimitAlarms := fbCore.xSuppressFlowAlarms;
GVL_Devices.fbV1.xAutoRun := fbCore.xV1Run;
GVL_Devices.fbV1.wInterlock := fbCore.wV1Interlock;
GVL_IO.xHA1 := fbCore.xHorn;
GVL_IO.xHL1 := fbCore.xLamp;
GVL_IO.xK1 := fbCore.xK1;

// 6. Сводка тревог (шаг 13): устройства, LIC101, станция
FOR uiIdx := 1 TO GVL_DeviceList.DEVICE_COUNT DO
    aitfSource[uiIdx] := GVL_DeviceList.aitfDevice[uiIdx];
END_FOR
aitfSource[GVL_DeviceList.DEVICE_COUNT + 1] := GVL_Station.fbLIC101;
aitfSource[GVL_DeviceList.DEVICE_COUNT + 2] := GVL_Station.fbAlarms;
GVL_Log.fbAlarmSummary(aitfSource := aitfSource, uiSourceCount := GVL_DeviceList.DEVICE_COUNT + 2,
                       itfTime := GVL_Time.fbClockMain, stView := GVL_Log.stAlarmView);

// 7. Журнал (шаг 14): аудит режимов устройств — с цикла после первого вызова устройств (до него режим устройства —
//    начальное значение, а не восстановленный: каждый старт давал бы событие 101018 по каждому устройству);
//    страница HMI и курсор — после всех событий цикла
IF xDevicesCalled THEN
    GVL_Log.fbDeviceAudit(aitfDevice := GVL_DeviceList.aitfDevice, auiDevNo := GVL_DeviceList.auiDevNo,
                          itfEvents := GVL_Log.fbEventLog);
END_IF
xDevicesCalled := TRUE;                                 // PRG_Devices выполняется следом в этом цикле
GVL_Log.fbEventLog.FillView(stView := GVL_Log.stEventView);
GVL_Log.fbEventLog.FillFeed(stFeed := GVL_Log.stEventFeed);

// 8. Состояние станции (шаг 15)
GVL_Station.stStationSts := fbCore.stSts;
