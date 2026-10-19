// 1. Сводный статус NE 107 (значения упорядочены по тяжести: MAX). Режим даёт CheckFunction: OutOfService, подмена
//    AI/DI (Manual) и Local — механизмом управляют по месту, выход ПЛК не действует (категория C NE 107, статус PA
//    «function check / local override», NE107-1)
xCfgBad := wCfgErr <> 0 OR NOT xCfgEverOk;
IF eMode = E_DeviceMode.OutOfService OR eMode = E_DeviceMode.Local
   OR (xManualIsCheck AND eMode = E_DeviceMode.Manual)
THEN
    eModeStatus := E_Ne107Status.CheckFunction;
END_IF
IF xCfgBad THEN
    eCfgStatus := E_Ne107Status.CheckFunction;
END_IF
eNe107 := F_Ne107Worst(eA := eDevStatus, eB := eModeStatus);
eNe107 := F_Ne107Worst(eA := eNe107, eB := eCfgStatus);
xFault := eNe107 = E_Ne107Status.Failure;
xAvailable := xAvailableDev AND xCfgEverOk;

// 2. Общий старший байт wStatus (раздел 5.2 контракта)
IF eMode = E_DeviceMode.Auto THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_MODE_AUTO;
ELSIF eMode = E_DeviceMode.Manual THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_MODE_MANUAL;
ELSIF eMode = E_DeviceMode.Local THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_MODE_LOCAL;
ELSIF eMode = E_DeviceMode.OutOfService THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_MODE_OOS;
END_IF
IF xCfgBad THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_CFG_ERROR;
END_IF
IF xFault THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_FAILURE;
END_IF
IF wWarnBits <> 0 OR eNe107 = E_Ne107Status.OutOfSpecification
   OR eNe107 = E_Ne107Status.MaintenanceRequired
THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_WARNING;
END_IF
IF wAlmUnack <> 0 THEN
    wHigh := wHigh OR GVL_Const.DEV_STS_ALARM_UNACK;
END_IF

// 3. Общий заголовок состояния
stCommon.wStatus := (wLow AND GVL_Const.WORD_LOW_BYTE) OR wHigh;
stCommon.wFault := wFaultBits;
stCommon.wWarning := wWarnBits;
stCommon.wCfgErr := wCfgErr;
stCommon.eMode := eMode;
stCommon.eNe107 := eNe107;
stCommon.eCmdResult := eCmdResult;
stCommon.uiCmdSeq := uiCmdSeq;
stCommon.wAlmActive := wAlmActive;
stCommon.wAlmUnack := wAlmUnack;
stCommon.wAlmShelved := wAlmShelved;
stCommon.ePrioUnack := ePrioUnack;
stCommon.eDevType := eDevType;
stCommon.wAlmSuppressed := wAlmSuppressed;

// 4. Конец цикла
ltPrevCall := ltNow;
xFirstCall := FALSE;
xResetReq := FALSE;
xAckAllReq := FALSE;
xModeReq := FALSE;
