// Добавить запись: сквозной номер, метки UTC и времени процесса; в полном кольце затирается самая старая.
// Всегда TRUE: кольцо не переполняется
METHOD PRIVATE Store : BOOL
VAR_INPUT
    eKind     : E_EventKind;
    ePriority : PL.E_AlarmPriority;
    udiId     : UDINT;
    eOldState : PL.E_AlarmState;
    eNewState : PL.E_AlarmState;
    eReason   : PL.E_AlarmEventReason;
    rValue    : REAL;
END_VAR
VAR
    uliUtc_ms  : ULINT;             // ответ часов реального времени
    itfTimeAct : PL.I_TimeSource;   // действующий источник времени процесса
END_VAR
