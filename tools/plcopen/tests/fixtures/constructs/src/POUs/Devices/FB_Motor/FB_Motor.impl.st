SUPER^();
IF stCmd.xStart AND NOT xFault THEN
    Start();
ELSIF stCmd.xStop THEN
    xRun := FALSE;
END_IF
