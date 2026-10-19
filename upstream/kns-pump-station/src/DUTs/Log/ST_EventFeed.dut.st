// Назначение: курсор журнала для внешних клиентов (GVL_Log.stEventFeed: сценарии ПМИ, SCADA) — записи от
//             старой к новой начиная с номера udiFromSeq, отдельно от страницы HMI. Клиент читает строки,
//             пишет udiFromSeq := номер последней прочитанной + 1 и повторяет; udiFromSeq < udiSeqFirst —
//             записи между опросами затёрты (пропуск номеров).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 3.2, 14.3
{attribute 'qualified_only'}
TYPE ST_EventFeed :
STRUCT
    udiFromSeq  : UDINT;            // пишет клиент: первый нужный номер
    udiSeqFirst : UDINT;            // самая старая запись в кольце (пустой журнал — udiSeqLast + 1)
    udiSeqLast  : UDINT;            // самая новая запись (0 — записей ещё не было)
    uiCount     : UINT;             // строк в astRow
    wReserve    : WORD;
    astRow      : ARRAY[1..GVL_Const.LOG_FEED_ROWS] OF ST_EventRecord;   // строки после uiCount — нули
END_STRUCT
END_TYPE
