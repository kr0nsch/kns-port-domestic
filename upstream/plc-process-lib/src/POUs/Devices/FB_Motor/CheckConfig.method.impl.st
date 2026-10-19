IF stCfgIn.xFbUsed AND (stCfgIn.tFbStart = T#0S OR stCfgIn.tFbStop = T#0S) THEN
    wErr := wErr OR GVL_Const.MOT_CFG_FB_TIMES;
END_IF
IF stCfgIn.uiMaxStartsPerHour > GVL_Const.STARTS_WINDOW_MAX THEN
    wErr := wErr OR GVL_Const.MOT_CFG_STARTS_LIMIT;
END_IF
IF stCfgIn.tResetWindow = T#0S OR stCfgIn.tResetPulse > stCfgIn.tResetWindow THEN
    wErr := wErr OR GVL_Const.MOT_CFG_RESET;
END_IF
IF NOT CheckAlarmCfg(astCfg := stCfgIn.astAlarm) THEN
    wErr := wErr OR GVL_Const.MOT_CFG_ALARM;
END_IF
CheckConfig := wErr;
