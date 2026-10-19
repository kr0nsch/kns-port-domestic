// Назначение: событие перехода тревоги для приёмника I_AlarmSink (журнал приложения).
//             Астрономическое время ставит приёмник, в событии — монотонная отметка LTIME.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Тревоги»
{attribute 'qualified_only'}
TYPE ST_AlarmEvent :
STRUCT
    udiId     : UDINT;                // номер тревоги на объекте
    ePriority : E_AlarmPriority;
    eOldState : E_AlarmState;
    eNewState : E_AlarmState;
    eReason   : E_AlarmEventReason;
    ltTime    : LTIME;                // монотонная отметка; астрономическое время ставит приёмник
    rValue    : REAL;                 // значение процесса в момент события
END_STRUCT
END_TYPE
