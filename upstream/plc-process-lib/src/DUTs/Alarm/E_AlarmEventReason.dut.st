// Назначение: причина перехода тревоги в событии ST_AlarmEvent (приёмник I_AlarmSink).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Тревоги»
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_AlarmEventReason :
(
    None          := 0,
    Activated     := 1,    // условие появилось (после задержки)
    Cleared       := 2,    // условие ушло (после задержки)
    Acked         := 3,
    Shelved       := 4,
    Unshelved     := 5,    // командой
    ShelveExpired := 6,    // по таймауту
    Suppressed    := 7,
    Unsuppressed  := 8,
    OosOn         := 9,
    OosOff        := 10,
    Disabled      := 11    // тревога выключена приоритетом None: закрывающее событие
) INT;
END_TYPE
