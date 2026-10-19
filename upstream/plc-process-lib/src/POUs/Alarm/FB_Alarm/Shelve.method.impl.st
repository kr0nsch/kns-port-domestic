IF stCfg.ePriority <> E_AlarmPriority.None AND stCfg.tShelveMax > T#0S
   AND eState <> E_AlarmState.OutOfService
THEN
    xShelveReq := TRUE;
    tShelveReq := tDuration;
    Shelve := TRUE;
ELSE
    Shelve := FALSE;
END_IF
