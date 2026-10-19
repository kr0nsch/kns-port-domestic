// 6. Shelve: срок отсчитывается от команды независимо от наложенных состояний
eShelveEnd := E_AlarmEventReason.None;
IF xShelved THEN
    // «время назад»: остаток не может быть больше срока (LTIME без знака — сравнение до вычитания)
    IF ltShelveEnd > ltNow THEN
        IF ltShelveEnd - ltNow > TIME_TO_LTIME(tShelveDur) THEN
            ltShelveEnd := ltNow + TIME_TO_LTIME(tShelveDur);
        END_IF
    END_IF
    IF xUnshelveReq THEN
        xShelved := FALSE;
        eShelveEnd := E_AlarmEventReason.Unshelved;
    ELSIF ltNow >= ltShelveEnd THEN
        xShelved := FALSE;
        eShelveEnd := E_AlarmEventReason.ShelveExpired;
    END_IF
END_IF
// новый запрос (в том числе повторный — срок отсчитывается заново); в OutOfService не принимается
IF xShelveReq AND NOT xOutOfService AND eState <> E_AlarmState.OutOfService
   AND stCfg.tShelveMax > T#0S
THEN
    IF tShelveReq = T#0S OR tShelveReq > stCfg.tShelveMax THEN
        tShelveDur := stCfg.tShelveMax;
    ELSE
        tShelveDur := tShelveReq;
    END_IF
    ltShelveEnd := ltNow + TIME_TO_LTIME(tShelveDur);
    xShelved := TRUE;
    eShelveEnd := E_AlarmEventReason.None;
END_IF
xShelveReq := FALSE;
xUnshelveReq := FALSE;
