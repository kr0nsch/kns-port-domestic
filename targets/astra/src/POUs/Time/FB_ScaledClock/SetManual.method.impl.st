IF xOn THEN
    xManual := TRUE;
    ltManual := ltStart;
ELSIF xManual THEN
    xManual := FALSE;
    xInit := TRUE;
    ltBaseScaled := ltManual;
    // PORT: [time] проверить в Astra.IDE — оператор LTIME(), монотонность (C11)
    ltBaseReal := LTIME();
END_IF
