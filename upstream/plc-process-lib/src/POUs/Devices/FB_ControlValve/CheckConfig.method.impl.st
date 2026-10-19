IF NOT F_IsFinite(rIn := stCfgIn.rOutMin_pct) OR NOT F_IsFinite(rIn := stCfgIn.rOutMax_pct)
   OR stCfgIn.rOutMin_pct < 0.0 OR stCfgIn.rOutMax_pct > GVL_Const.PCT_FULL
   OR stCfgIn.rOutMin_pct >= stCfgIn.rOutMax_pct
THEN
    wErr := wErr OR GVL_Const.CV_CFG_LIMITS;
END_IF
IF NOT F_IsFinite(rIn := stCfgIn.rRateUp_pctps) OR NOT F_IsFinite(rIn := stCfgIn.rRateDown_pctps)
   OR stCfgIn.rRateUp_pctps < 0.0 OR stCfgIn.rRateDown_pctps < 0.0
THEN
    wErr := wErr OR GVL_Const.CV_CFG_RATE;
END_IF
IF NOT F_IsFinite(rIn := stCfgIn.rSafePos_pct) OR stCfgIn.rSafePos_pct < 0.0
   OR stCfgIn.rSafePos_pct > GVL_Const.PCT_FULL
THEN
    wErr := wErr OR GVL_Const.CV_CFG_SAFE_POS;
END_IF
IF stCfgIn.xFbUsed AND (NOT F_IsFinite(rIn := stCfgIn.rDevMax_pct) OR stCfgIn.rDevMax_pct <= 0.0
                        OR stCfgIn.tDev <= T#0S)
THEN
    wErr := wErr OR GVL_Const.CV_CFG_DEVIATION;
END_IF
IF NOT F_IsFinite(rIn := stCfgIn.rTightShut_pct) OR stCfgIn.rTightShut_pct < 0.0
   OR stCfgIn.rTightShut_pct >= stCfgIn.rOutMax_pct
THEN
    wErr := wErr OR GVL_Const.CV_CFG_TIGHT_SHUT;
END_IF
IF stCfgIn.eFaultAction <> E_CvFaultAction.Hold AND stCfgIn.eFaultAction <> E_CvFaultAction.SafePos THEN
    wErr := wErr OR GVL_Const.CV_CFG_FAULT_ACTION;
END_IF
IF NOT CheckAlarmCfg(astCfg := stCfgIn.astAlarm) THEN
    wErr := wErr OR GVL_Const.CV_CFG_ALARM;
END_IF
CheckConfig := wErr;
