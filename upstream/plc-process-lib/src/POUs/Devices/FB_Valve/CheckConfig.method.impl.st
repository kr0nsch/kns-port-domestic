xMotor := stCfgIn.eType = E_ValveType.Motorized;
xSolenoid := stCfgIn.eType = E_ValveType.SolenoidEto OR stCfgIn.eType = E_ValveType.SolenoidEtc;
IF NOT xMotor AND NOT xSolenoid THEN
    wErr := wErr OR GVL_Const.VLV_CFG_TYPE;
END_IF
IF stCfgIn.tTravel <= T#0S THEN
    wErr := wErr OR GVL_Const.VLV_CFG_TRAVEL;
END_IF
IF (stCfgIn.eSafePos <> E_ValveSafePos.Closed AND stCfgIn.eSafePos <> E_ValveSafePos.Open
    AND stCfgIn.eSafePos <> E_ValveSafePos.Stay)
   OR (xSolenoid AND stCfgIn.eSafePos = E_ValveSafePos.Stay)
THEN
    wErr := wErr OR GVL_Const.VLV_CFG_SAFE_POS;
END_IF
IF (stCfgIn.xCloseOnTorque AND NOT stCfgIn.xTorqueUsed) OR (xSolenoid AND stCfgIn.xTorqueUsed) THEN
    wErr := wErr OR GVL_Const.VLV_CFG_TORQUE;
END_IF
IF xMotor AND stCfgIn.tReverse <= T#0S THEN
    wErr := wErr OR GVL_Const.VLV_CFG_REVERSE;
END_IF
IF stCfgIn.tResetWindow <= T#0S THEN
    wErr := wErr OR GVL_Const.VLV_CFG_RESET;
END_IF
IF NOT CheckAlarmCfg(astCfg := stCfgIn.astAlarm) THEN
    wErr := wErr OR GVL_Const.VLV_CFG_ALARM;
END_IF
CheckConfig := wErr;
