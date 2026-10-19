// Страница журнала для HMI: номер страницы stView.uiPage (0 — новые) ограничивается последней страницей,
// строки — новые сверху; строки после последней записи — пустые (udiSeq = 0)
METHOD FillView
VAR_IN_OUT
    stView : ST_EventView;          // GVL_Log.stEventView
END_VAR
VAR
    uiRow      : UINT;              // строка страницы
    uiAgeFirst : UINT;              // возраст записи первой строки
END_VAR
