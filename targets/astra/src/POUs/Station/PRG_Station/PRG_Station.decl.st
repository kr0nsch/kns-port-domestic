// Назначение: программа станции (MainTask, после PRG_DeviceList, до PRG_Devices) — привязка ядра
//             FB_StationCore к сгенерированному слою, журналу и сводке тревог (DESIGN 7)
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 7
PROGRAM PRG_Station
VAR
    fbCore           : FB_StationCore;                                           // шаги 2–15 (6.15)
    aitfPump         : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF PL.I_MotorVfd;      // насосы для ядра
    aitfSource       : ARRAY[1..GVL_Const.ALM_SOURCE_MAX] OF PL.I_AlarmSource;   // источники сводки
    itfDevice        : PL.I_Device;                                              // устройство списка
    uiIdx            : UINT;                                                     // насос, устройство, приоритет
    xAckIdFound      : BOOL;                                                     // ответ сводки на udiAckId
    xShelveIdFound   : BOOL;                                                     // … на udiShelveId
    xUnshelveIdFound : BOOL;                                                     // … на udiUnshelveId
    xDevicesCalled   : BOOL;                                                     // PRG_Devices уже выполнялся
END_VAR
