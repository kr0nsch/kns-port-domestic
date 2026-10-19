// I_StationEventSink: событие станции — запись вида Station с номером STN_EVENT_ID_BASE + код, приоритетом
// None и состояниями Normal; TRUE — записано
METHOD LogEvent : BOOL
VAR_INPUT
    eEvent : E_StationEvent;        // номер записи = STN_EVENT_ID_BASE + eEvent
    rValue : REAL;                  // аргумент (номер насоса, параметра, строк…)
END_VAR
