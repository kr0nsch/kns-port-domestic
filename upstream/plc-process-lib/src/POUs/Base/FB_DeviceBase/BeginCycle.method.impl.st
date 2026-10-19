ResolveTime();
ltNow := itfTimeAct.Now();
IF NOT xFirstCall AND ltNow >= ltPrevCall THEN
    ltDt := ltNow - ltPrevCall;
ELSE
    ltDt := LTIME#0S;
END_IF
