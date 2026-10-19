SUPER^();
tonDelay(IN := xStart, PT := stCfg.tStartDelay);
xRunning := tonDelay.Q AND NOT xFault;
IF xRunning THEN
    Start();
ELSE
    Stop();
END_IF
