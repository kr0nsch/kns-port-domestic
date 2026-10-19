wErr := SUPER^.CheckConfig(stCfgIn := stCfgIn);
stVfdChk := stCfgIn.stVfd;
IF NOT F_IsFinite(rIn := stVfdChk.rSpeedMin_pct) OR NOT F_IsFinite(rIn := stVfdChk.rSpeedMax_pct) THEN
    wErr := wErr OR GVL_Const.MOT_CFG_VFD_SPEED_LIMITS;
ELSIF stVfdChk.rSpeedMin_pct < 0.0 OR stVfdChk.rSpeedMax_pct > GVL_Const.PCT_FULL
      OR stVfdChk.rSpeedMin_pct >= stVfdChk.rSpeedMax_pct
THEN
    wErr := wErr OR GVL_Const.MOT_CFG_VFD_SPEED_LIMITS;
END_IF
IF NOT F_IsFinite(rIn := stVfdChk.rRampUp_pctps) OR NOT F_IsFinite(rIn := stVfdChk.rRampDown_pctps) THEN
    wErr := wErr OR GVL_Const.MOT_CFG_VFD_RAMP;
ELSIF stVfdChk.rRampUp_pctps < 0.0 OR stVfdChk.rRampDown_pctps < 0.0 THEN
    wErr := wErr OR GVL_Const.MOT_CFG_VFD_RAMP;
END_IF
// TIME без знака: «<= T#0S» — то же, что «= T#0S» (PLCopen CP28: время не сравнивают на равенство)
IF stVfdChk.tCommLoss <= T#0S THEN
    wErr := wErr OR GVL_Const.MOT_CFG_VFD_COMM;
END_IF
IF NOT F_IsFinite(rIn := stVfdChk.rSpeedDev_pct) THEN
    wErr := wErr OR GVL_Const.MOT_CFG_VFD_SPEED_DEV;
ELSIF stVfdChk.rSpeedDev_pct < 0.0 OR (stVfdChk.rSpeedDev_pct > 0.0 AND stVfdChk.tSpeedDev <= T#0S) THEN
    wErr := wErr OR GVL_Const.MOT_CFG_VFD_SPEED_DEV;
END_IF
CheckConfig := wErr;
