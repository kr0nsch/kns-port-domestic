IF NOT (stCfgIn.eFailValue = E_DiFailValue.HoldLast OR stCfgIn.eFailValue = E_DiFailValue.ForceFalse
        OR stCfgIn.eFailValue = E_DiFailValue.ForceTrue)
THEN
    wErr := wErr OR GVL_Const.DI_CFG_FAIL_VALUE;
END_IF
IF NOT CheckAlarmCfg(astCfg := stCfgIn.astAlarm) THEN
    wErr := wErr OR GVL_Const.DI_CFG_ALARM;
END_IF
CheckConfig := wErr;
