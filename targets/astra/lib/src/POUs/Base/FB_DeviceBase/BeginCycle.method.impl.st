ResolveTime();
ltNow := itfTimeAct.Now();
IF NOT xFirstCall AND ltNow >= ltPrevCall THEN
    ltDt := ltNow - ltPrevCall;
ELSE
    // PORT: [types] проверить в Astra.IDE — литералы и преобразования LTIME (C11)
    ltDt := LTIME#0S;
END_IF
