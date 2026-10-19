// 1. Исправный преобразователь: линейная шкала и насыщение на границах измерения NE 43
IF PL.F_IsFinite(rIn := rValue) AND PL.F_IsFinite(rIn := rRangeLo) AND PL.F_IsFinite(rIn := rRangeHi)
   AND rRangeHi > rRangeLo THEN
    rMeas_mA := PL.GVL_Const.MA_ZERO + PL.GVL_Const.MA_SPAN * (rValue - rRangeLo) / (rRangeHi - rRangeLo);
    rMeas_mA := LIMIT(PL.GVL_Const.NE43_MEAS_LOW_MA, rMeas_mA, PL.GVL_Const.NE43_MEAS_HIGH_MA);
ELSE
    rMeas_mA := GVL_Const.SIM_MA_FAIL_LOW;
END_IF

// 2. Инъекция отказа (Freeze — ток прошлого вызова не меняется)
CASE eFault OF
    E_SimAiFault.WireBreak:
        rCurrent_mA := 0.0;
    E_SimAiFault.FailLow:
        rCurrent_mA := GVL_Const.SIM_MA_FAIL_LOW;
    E_SimAiFault.FailHigh:
        rCurrent_mA := GVL_Const.SIM_MA_FAIL_HIGH;
    E_SimAiFault.UnderRange:
        rCurrent_mA := GVL_Const.SIM_MA_UNDER_RANGE;
    E_SimAiFault.OverRange:
        rCurrent_mA := GVL_Const.SIM_MA_OVER_RANGE;
    E_SimAiFault.Freeze:
        // последнее значение тока
        ;
    E_SimAiFault.Forced:
        IF PL.F_IsFinite(rIn := rForced_mA) THEN
            rCurrent_mA := rForced_mA;
        ELSE
            rCurrent_mA := 0.0;
        END_IF
ELSE
    rCurrent_mA := rMeas_mA;
END_CASE
