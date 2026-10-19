IF lrValue <= 0.0 THEN
    FloorU := 0;
    RETURN;
END_IF
udiRound := LREAL_TO_UDINT(lrValue);
IF UDINT_TO_LREAL(udiRound) > lrValue THEN
    udiRound := udiRound - 1;
END_IF
FloorU := udiRound;
