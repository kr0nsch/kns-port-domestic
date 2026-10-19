// Назначение: запись журнала событий FB_EventLog (кольцо LOG_CAPACITY записей). 40 байт: 32-битные поля
//             на смещениях, кратных 4, ULINT и LREAL — кратных 8 (тест EventRecordSizeIs40).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.2
{attribute 'qualified_only'}
TYPE ST_EventRecord :
STRUCT
    udiSeq    : UDINT;                  // сквозной номер с запуска приложения, с 1
    eKind     : E_EventKind;
    ePriority : PL.E_AlarmPriority;     // события станции — None
    udiId     : UDINT;                  // номер тревоги или 101000 + код события
    eOldState : PL.E_AlarmState;        // события станции — Normal
    eNewState : PL.E_AlarmState;
    eReason   : PL.E_AlarmEventReason;  // события станции — None
    wReserve  : WORD;                   // выравнивание: дальше 32- и 64-битные поля
    rValue    : REAL;                   // значение процесса или аргумент события
    uliUtc_ms : ULINT;                  // UTC, мс от 1970 (SysTimeRtcHighResGet); 0 — часы недоступны
    lrMono_s  : LREAL;                  // время процесса, с (I_TimeSource журнала = GVL_Time.fbClockMain)
END_STRUCT
END_TYPE
