wCfgErr := wErr;
IF wErr = 0 THEN
    xCfgEverOk := TRUE;
    AcceptCfg := TRUE;
ELSE
    AcceptCfg := FALSE;
END_IF
