// бит 0: действие — значение перечисления (сравнениями: строгое перечисление, L4 контракта)
IF stCfgIn.eAction <> E_PidAction.Reverse AND stCfgIn.eAction <> E_PidAction.Direct THEN
    wErr := wErr OR GVL_Const.PID_CFG_ACTION;
END_IF
// бит 1: Kp > 0
IF NOT F_IsFinite(rIn := stCfgIn.rKp) OR stCfgIn.rKp <= 0.0 THEN
    wErr := wErr OR GVL_Const.PID_CFG_KP;
END_IF
// бит 2: Ti >= 0, Td >= 0
IF NOT F_IsFinite(rIn := stCfgIn.rTi_s) OR NOT F_IsFinite(rIn := stCfgIn.rTd_s)
   OR stCfgIn.rTi_s < 0.0 OR stCfgIn.rTd_s < 0.0
THEN
    wErr := wErr OR GVL_Const.PID_CFG_TI_TD;
END_IF
// бит 3: фильтр Д — N в PID_DFILTER_N_MIN…MAX при Td > 0; неконечное N — всегда ошибка
IF NOT F_IsFinite(rIn := stCfgIn.rDFilterN)
   OR (stCfgIn.rTd_s > 0.0 AND (stCfgIn.rDFilterN < GVL_Const.PID_DFILTER_N_MIN
                                OR stCfgIn.rDFilterN > GVL_Const.PID_DFILTER_N_MAX))
THEN
    wErr := wErr OR GVL_Const.PID_CFG_DFILTER;
END_IF
// бит 4: Tt >= 0 (0 — авто)
IF NOT F_IsFinite(rIn := stCfgIn.rTt_s) OR stCfgIn.rTt_s < 0.0 THEN
    wErr := wErr OR GVL_Const.PID_CFG_TT;
END_IF
// бит 5: диапазон PV
IF NOT F_IsFinite(rIn := stCfgIn.rPvMin_eu) OR NOT F_IsFinite(rIn := stCfgIn.rPvMax_eu)
   OR stCfgIn.rPvMin_eu >= stCfgIn.rPvMax_eu
THEN
    wErr := wErr OR GVL_Const.PID_CFG_PV_RANGE;
END_IF
// бит 6: пределы задания (равные допустимы — задание фиксировано)
IF NOT F_IsFinite(rIn := stCfgIn.rSpMin_eu) OR NOT F_IsFinite(rIn := stCfgIn.rSpMax_eu)
   OR stCfgIn.rSpMin_eu > stCfgIn.rSpMax_eu
THEN
    wErr := wErr OR GVL_Const.PID_CFG_SP_RANGE;
END_IF
// бит 7: пределы выхода в 0…100 %, min < max
IF NOT F_IsFinite(rIn := stCfgIn.rOutMin_pct) OR NOT F_IsFinite(rIn := stCfgIn.rOutMax_pct)
   OR stCfgIn.rOutMin_pct < 0.0 OR stCfgIn.rOutMax_pct > GVL_Const.PCT_FULL
   OR stCfgIn.rOutMin_pct >= stCfgIn.rOutMax_pct
THEN
    wErr := wErr OR GVL_Const.PID_CFG_OUT_RANGE;
END_IF
// бит 8: зона нечувствительности в 0…PID_DEADBAND_MAX_PCT
IF NOT F_IsFinite(rIn := stCfgIn.rDeadband_pct) OR stCfgIn.rDeadband_pct < 0.0
   OR stCfgIn.rDeadband_pct > GVL_Const.PID_DEADBAND_MAX_PCT
THEN
    wErr := wErr OR GVL_Const.PID_CFG_DEADBAND;
END_IF
// бит 9: скорости рампы задания и выхода >= 0 (0 — без ограничения)
IF NOT F_IsFinite(rIn := stCfgIn.rSpRate_ups) OR NOT F_IsFinite(rIn := stCfgIn.rOutRate_pctps)
   OR stCfgIn.rSpRate_ups < 0.0 OR stCfgIn.rOutRate_pctps < 0.0
THEN
    wErr := wErr OR GVL_Const.PID_CFG_RATES;
END_IF
// бит 10: tDtMax > 0, tSample < tDtMax
IF stCfgIn.tDtMax = T#0S OR stCfgIn.tSample >= stCfgIn.tDtMax THEN
    wErr := wErr OR GVL_Const.PID_CFG_SAMPLE;
END_IF
// бит 11: реакция на отказ PV — значение перечисления; безопасный выход в пределах выхода
IF (stCfgIn.ePvFailAction <> E_PidPvFailAction.Hold AND stCfgIn.ePvFailAction <> E_PidPvFailAction.SafeOut
    AND stCfgIn.ePvFailAction <> E_PidPvFailAction.ShedToManual)
   OR NOT F_IsFinite(rIn := stCfgIn.rSafeOut_pct)
   OR stCfgIn.rSafeOut_pct < stCfgIn.rOutMin_pct OR stCfgIn.rSafeOut_pct > stCfgIn.rOutMax_pct
THEN
    wErr := wErr OR GVL_Const.PID_CFG_PV_FAIL;
END_IF
// бит 12: приоритеты тревог — значения перечисления
IF NOT CheckAlarmCfg(astCfg := stCfgIn.astAlarm) THEN
    wErr := wErr OR GVL_Const.PID_CFG_ALARM;
END_IF
CheckConfig := wErr;
