// Назначение: аудит режимов устройств перечня (GVL_Log.fbDeviceAudit, MainTask после PRG_Devices… вызывает
//             PRG_Station): смена Mode устройства — событие станции 101018 со значением dev_no · 10 + режим
//             (E_DeviceMode). Первый вызов запоминает режимы без событий (режимы после старта — из retain).
// Автор:      kr0nsch
// Версия:     0.1.1
// Документ:   docs/DESIGN.md, раздел 9.3; docs/04_algorithms.md, раздел 16
FUNCTION_BLOCK FB_DeviceAudit
VAR_INPUT
    aitfDevice : ARRAY[1..GVL_DeviceList.DEVICE_COUNT] OF PL.I_Device;   // GVL_DeviceList.aitfDevice
    auiDevNo   : ARRAY[1..GVL_DeviceList.DEVICE_COUNT] OF UINT;          // GVL_DeviceList.auiDevNo
    itfEvents  : I_StationEventSink;                                     // журнал; 0 — без событий
END_VAR
VAR_OUTPUT
    udiChanges : UDINT;             // замечено смен режима с запуска
END_VAR
VAR
    aeModePrev : ARRAY[1..GVL_DeviceList.DEVICE_COUNT] OF PL.E_DeviceMode;   // режим прошлого вызова
    axKnown    : ARRAY[1..GVL_DeviceList.DEVICE_COUNT] OF BOOL;             // режим устройства уже запомнен
    uiI        : UINT;              // индекс устройства
    eMode      : PL.E_DeviceMode;   // режим этого вызова
    itfDev     : PL.I_Device;       // устройство
END_VAR
