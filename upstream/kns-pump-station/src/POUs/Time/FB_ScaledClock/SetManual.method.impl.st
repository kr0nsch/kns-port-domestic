IF xOn THEN
    xManual := TRUE;
    ltManual := ltStart;
ELSIF xManual THEN
    xManual := FALSE;
    xInit := TRUE;
    ltBaseScaled := ltManual;
    ltBaseReal := LTIME();
END_IF
