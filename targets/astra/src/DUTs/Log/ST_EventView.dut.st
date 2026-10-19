// Назначение: страница журнала для HMI (GVL_Log.stEventView): новые записи сверху, uiPage пишет HMI.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.2
{attribute 'qualified_only'}
TYPE ST_EventView :
STRUCT
    uiPage      : UINT;             // пишет HMI: 0 — новые; больше последней — последняя страница
    uiPageCount : UINT;             // страниц (не меньше 1)
    uiCount     : UINT;             // записей в журнале
    wReserve    : WORD;
    astRow      : ARRAY[1..GVL_Const.LOG_VIEW_ROWS] OF ST_EventRecord;   // пустые строки — udiSeq = 0
END_STRUCT
END_TYPE
