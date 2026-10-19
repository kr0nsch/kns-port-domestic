IF NOT (stCfgIn.eInput = E_AiInputType.MilliAmp OR stCfgIn.eInput = E_AiInputType.Norm420
        OR stCfgIn.eInput = E_AiInputType.Norm01 OR stCfgIn.eInput = E_AiInputType.Eng
        OR stCfgIn.eInput = E_AiInputType.Raw)
THEN
    wErr := wErr OR GVL_Const.AI_CFG_INPUT_TYPE;
END_IF
IF NOT (F_IsFinite(rIn := stCfgIn.rRangeLo_eu) AND F_IsFinite(rIn := stCfgIn.rRangeHi_eu)
        AND stCfgIn.rRangeLo_eu < stCfgIn.rRangeHi_eu)
THEN
    wErr := wErr OR GVL_Const.AI_CFG_RANGE;
END_IF

// Уставки: включённые — в шкале, гистерезис 0 <= h < диапазона, порядок строго LL < L < H < HH
// (обход от HH к LL: каждая следующая включённая строго меньше предыдущей включённой)
rSpan := stCfgIn.rRangeHi_eu - stCfgIn.rRangeLo_eu;
FOR uiIdx := E_AiAlarm.HH TO E_AiAlarm.LL DO
    stLim := stCfgIn.astLimit[uiIdx];
    IF stLim.xEnable THEN
        IF NOT (stLim.rSetpoint_eu >= stCfgIn.rRangeLo_eu AND stLim.rSetpoint_eu <= stCfgIn.rRangeHi_eu) THEN
            wErr := wErr OR GVL_Const.AI_CFG_LIMIT_OUT_OF_RANGE;
        END_IF
        IF NOT (F_IsFinite(rIn := stLim.rHyst_eu) AND stLim.rHyst_eu >= 0.0 AND stLim.rHyst_eu < rSpan) THEN
            wErr := wErr OR GVL_Const.AI_CFG_HYST;
        END_IF
        IF xPrev AND NOT (stLim.rSetpoint_eu < rPrevSp) THEN
            wErr := wErr OR GVL_Const.AI_CFG_LIMIT_ORDER;
        END_IF
        xPrev := TRUE;
        rPrevSp := stLim.rSetpoint_eu;
    END_IF
END_FOR

IF NOT (stCfgIn.rLowCut_pct >= 0.0 AND stCfgIn.rLowCut_pct <= GVL_Const.AI_LOWCUT_MAX_PCT) THEN
    wErr := wErr OR GVL_Const.AI_CFG_LOW_CUT;
END_IF
IF NOT (stCfgIn.eFailValue = E_AiFailValue.HoldLast OR stCfgIn.eFailValue = E_AiFailValue.Substitute)
   OR NOT F_IsFinite(rIn := stCfgIn.rFailValue_eu)
THEN
    wErr := wErr OR GVL_Const.AI_CFG_FAIL_VALUE;
END_IF
IF NOT CheckAlarmCfg(astCfg := stCfgIn.astAlarm) THEN
    wErr := wErr OR GVL_Const.AI_CFG_ALARM;
END_IF
// шкала отсчётов проверяется только у входа Raw: умолчания 0/0 проходят у остальных типов
IF stCfgIn.eInput = E_AiInputType.Raw
   AND NOT (F_IsFinite(rIn := stCfgIn.rRawLo_cnt) AND F_IsFinite(rIn := stCfgIn.rRawHi_cnt)
            AND stCfgIn.rRawLo_cnt < stCfgIn.rRawHi_cnt)
THEN
    wErr := wErr OR GVL_Const.AI_CFG_RAW_RANGE;
END_IF
CheckConfig := wErr;
