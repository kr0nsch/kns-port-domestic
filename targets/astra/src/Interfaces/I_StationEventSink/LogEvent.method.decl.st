// Записать событие станции; TRUE — записано
METHOD LogEvent : BOOL
VAR_INPUT
    eEvent : E_StationEvent;        // номер записи = STN_EVENT_ID_BASE + eEvent
    rValue : REAL;                  // аргумент (номер насоса, параметра, строк…)
END_VAR
