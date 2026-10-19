uBits.rValue := rIn;
IF (uBits.dwValue AND GVL_Const.REAL_EXP_MASK) = GVL_Const.REAL_EXP_MASK THEN
    // экспонента из одних единиц: NaN, +Inf или -Inf
    F_IsFinite := FALSE;
ELSE
    // конечное число: ABS не дойдёт до NaN
    F_IsFinite := ABS(rIn) <= GVL_Const.REAL_SANE_MAX;
END_IF
