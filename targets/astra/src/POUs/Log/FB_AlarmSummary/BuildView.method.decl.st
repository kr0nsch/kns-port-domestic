// Пересчитать список тревог не в Normal: сортировка вставкой по ключу (группа, приоритет, время перехода),
// в списке — первые ALM_VIEW_ROWS; uiActiveTotal — все тревоги не в Normal
METHOD PRIVATE BuildView
VAR_IN_OUT
    stView : ST_AlarmView;
END_VAR
VAR
    aiGroup  : ARRAY[1..GVL_Const.ALM_VIEW_ROWS] OF INT;     // группа: 0 — неквитированные, 1 — активные, 2 — прочие
    aiPrio   : ARRAY[1..GVL_Const.ALM_VIEW_ROWS] OF INT;     // приоритет строки
    alrTime  : ARRAY[1..GVL_Const.ALM_VIEW_ROWS] OF LREAL;   // время перехода строки
    stEmpty  : ST_AlarmViewRow;     // пустая строка
    uiTotal  : UINT;                // тревог не в Normal
    uiSrc    : UINT;
    uiK      : UINT;
    uiSlot   : UINT;
    iPos     : INT;                 // позиция вставки
    iJ       : INT;                 // строка списка (циклы вниз — со знаком)
    iCount   : INT;                 // строк в списке
    itfSrc   : PL.I_AlarmSource;   // источник
    itfAlm   : PL.I_Alarm;
    eState   : PL.E_AlarmState;
    iGroup   : INT;
    iPrio    : INT;
    lrTime   : LREAL;
END_VAR
