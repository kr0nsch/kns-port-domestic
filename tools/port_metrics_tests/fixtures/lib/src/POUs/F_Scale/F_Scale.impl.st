F_Scale := rIn * rK;
IF rK = 0.0 THEN
    F_Scale := 0.0;
END_IF
IF F_Scale > 1.0E6 THEN
    F_Scale := 1.0E6;
END_IF
