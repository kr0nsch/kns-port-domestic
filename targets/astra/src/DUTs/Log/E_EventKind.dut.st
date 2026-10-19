// Назначение: вид записи журнала (ST_EventRecord.eKind): событие тревоги PL.FB_Alarm или событие станции.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.2
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_EventKind :
(
    Alarm   := 1,   // переход тревоги (PL.I_AlarmSink.OnAlarmEvent)
    Station := 2    // событие станции (I_StationEventSink.LogEvent), номер 101000 + код
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
