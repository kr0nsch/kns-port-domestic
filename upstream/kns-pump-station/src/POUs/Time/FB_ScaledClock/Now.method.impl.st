IF xManual THEN
    Now := ltManual;
    RETURN;
END_IF

ltReal := LTIME();
IF NOT xInit THEN
    // первый вызов: при k = 1 часы совпадают с системным временем
    xInit := TRUE;
    ltBaseReal := ltReal;
    ltBaseScaled := ltReal;
END_IF
Now := ScaledAt(ltReal := ltReal);
