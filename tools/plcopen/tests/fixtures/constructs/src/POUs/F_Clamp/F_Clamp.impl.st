// границы в правильном порядке
IF rMin <= rMax THEN
    rLow := rMin;
    rHigh := rMax;
ELSE
    rLow := rMax;
    rHigh := rMin;
END_IF
F_Clamp := LIMIT(rLow, rValue, rHigh);
