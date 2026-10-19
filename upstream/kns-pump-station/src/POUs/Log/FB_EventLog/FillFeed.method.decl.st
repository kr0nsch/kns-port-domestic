// Курсор внешнего клиента: до LOG_FEED_ROWS записей от номера MAX(stFeed.udiFromSeq, самая старая) к новым.
// udiFromSeq < udiSeqFirst — клиент пропустил затёртые записи (видит по номерам)
METHOD FillFeed
VAR_IN_OUT
    stFeed : ST_EventFeed;          // GVL_Log.stEventFeed
END_VAR
VAR
    udiSeq  : UDINT;                // номер записи очередной строки
    uiRow   : UINT;                 // строка курсора
    stEmpty : ST_EventRecord;       // пустая строка
END_VAR
