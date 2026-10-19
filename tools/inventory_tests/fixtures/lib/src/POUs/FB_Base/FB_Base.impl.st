(* LTIME() в блочном комментарии *)
ltLast := LTIME();
pValue := ADR(diCount);
refValue REF= diCount;
IF __ISVALIDREF(refValue) THEN
    diCount := diCount + 1;
END_IF
