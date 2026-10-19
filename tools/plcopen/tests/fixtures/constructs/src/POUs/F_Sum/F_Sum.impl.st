F_Sum := 0;
FOR diIdx := LOWER_BOUND(arValues, 1) TO UPPER_BOUND(arValues, 1) DO
    F_Sum := F_Sum + arValues[diIdx];
END_FOR
