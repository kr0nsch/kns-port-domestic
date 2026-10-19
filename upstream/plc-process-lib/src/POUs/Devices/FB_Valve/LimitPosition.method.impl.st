xOpenLs := stCfgLkg.xZsoUsed AND xZso;
xCloseLs := stCfgLkg.xZscUsed AND xZsc;
IF xOpenLs AND xCloseLs THEN
    LimitPosition := E_ValveState.Unknown;
ELSIF xOpenLs THEN
    LimitPosition := E_ValveState.Open;
ELSIF xCloseLs THEN
    LimitPosition := E_ValveState.Closed;
ELSIF stCfgLkg.xZsoUsed OR stCfgLkg.xZscUsed THEN
    LimitPosition := E_ValveState.Intermediate;
ELSE
    LimitPosition := E_ValveState.Unknown;
END_IF
