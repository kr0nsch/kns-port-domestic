// Назначение: строка CSV журнала (ASCII, «;», CRLF): seq;time_utc;kind;id;code;priority;old_state;new_state;
//             reason;value — номер, UTC ISO 8601 (пусто без часов), alarm/station, номер, код F_AlarmCode,
//             числовые значения перечислений, значение REAL_TO_STRING. Русский текст подставляет
//             tools_project/eventlog_decode.py на хосте.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 9.2
FUNCTION F_EventCsvLine : STRING(GVL_Const.LOG_CSV_LINE_LEN)
VAR_INPUT
    stRecord : ST_EventRecord;      // запись журнала
END_VAR
VAR
    sKind : STRING(GVL_Const.LOG_SUFFIX_LEN);   // вид записи
    sHead : STRING(GVL_Const.LOG_CSV_LINE_LEN); // seq;time_utc;kind;id;code;
    sTail : STRING(GVL_Const.LOG_CSV_LINE_LEN); // priority;old_state;new_state;reason;
END_VAR
VAR CONSTANT
    SEP  : STRING := ';';
    CRLF : STRING := '$R$N';
END_VAR
