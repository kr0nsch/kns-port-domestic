// Назначение: строка списка тревог не в Normal (баннер, экран «Тревоги», сценарии ПМИ).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.2
{attribute 'qualified_only'}
TYPE ST_AlarmViewRow :
STRUCT
    udiId          : UDINT;
    ePriority      : PL.E_AlarmPriority;
    eState         : PL.E_AlarmState;
    uiSource       : UINT;          // индекс источника в FB_AlarmSummary (устройства — индекс GVL_DeviceList)
    uiSlot         : UINT;
    uliSinceUtc_ms : ULINT;         // время последнего перехода, замеченного сводкой
END_STRUCT
END_TYPE
