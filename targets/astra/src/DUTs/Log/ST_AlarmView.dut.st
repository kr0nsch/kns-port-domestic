// Назначение: список тревог не в Normal (GVL_Log.stAlarmView): неквитированные выше, затем активные по
//             приоритету, затем подавленные и отложенные, внутри группы — новые выше.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.2
{attribute 'qualified_only'}
TYPE ST_AlarmView :
STRUCT
    uiCount       : UINT;           // строк в astRow
    uiActiveTotal : UINT;           // настоящее число тревог не в Normal (может быть больше ALM_VIEW_ROWS)
    udiRevision   : UDINT;          // +1 при каждом пересчёте
    astRow        : ARRAY[1..GVL_Const.ALM_VIEW_ROWS] OF ST_AlarmViewRow;
END_STRUCT
END_TYPE
