// общая логика базы: сброс по входу
IF xReset THEN
    Reset(xForce := FALSE);
END_IF
xFault := xFaultInt;
