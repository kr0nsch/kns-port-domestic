// Назначение: журнал событий, сводка тревог и обмен MainTask ↔ SlowTask при выгрузке журнала в CSV.
// Автор:      kr0nsch
// Версия:     0.1.1
// Документ:   docs/DESIGN.md, раздел 4.3
{attribute 'qualified_only'}
VAR_GLOBAL
    fbEventLog      : FB_EventLog;       // приёмник PL.I_AlarmSink и I_StationEventSink
    fbAlarmSummary  : FB_AlarmSummary;
    fbDeviceAudit   : FB_DeviceAudit;    // смена режимов устройств → событие 101018 (раздел 9.3)
    stEventView     : ST_EventView;      // страница журнала HMI (uiPage — ReadWrite)
    stEventFeed     : ST_EventFeed;      // курсор журнала внешнего клиента (udiFromSeq — ReadWrite)
    stAlarmView     : ST_AlarmView;      // тревоги не в Normal: баннер, таблица, сценарии (Read)
    xExportReq      : BOOL;              // MainTask → SlowTask: снимок готов (снимает PRG_Slow при старте)
    eExportState    : E_LogExportState;  // SlowTask → MainTask
    udiExportError  : UDINT;             // код ошибки FILE.* последней выгрузки
    uiExportLines   : UINT;
END_VAR
