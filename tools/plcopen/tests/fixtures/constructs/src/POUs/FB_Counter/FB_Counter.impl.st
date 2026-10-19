fbEdge(CLK := xIn);
xEdge := fbEdge.Q;
IF xEdge THEN
    udiCount := udiCount + 1;
    udiTotal := udiTotal + 1;
END_IF
fbDelay(IN := xIn, PT := tConfirm, Q => xConfirmed);
stCmd.xStart S= xConfirmed;
stCmd.xStop R= xConfirmed;
