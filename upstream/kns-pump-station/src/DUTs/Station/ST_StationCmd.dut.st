// Назначение: команды станции (GVL_Station.stStationCmd) — пишут HMI, OPC UA, MQTT. Импульсы и
//             номера обрабатывает и сбрасывает PRG_Station в том же цикле (04 §19.2); результат —
//             stStationSts.eCmdResult и uiCmdSeq.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
TYPE ST_StationCmd :
STRUCT
    xSetAuto      : BOOL;           // импульс: станция в «Автомат» (04 §19.2)
    xSetManual    : BOOL;           // импульс: в «Ручной»; старше xSetAuto
    xSetStepped   : BOOL;           // импульс: способ «ступенчатое»; старше xSetLevelPid
    xSetLevelPid  : BOOL;           // импульс: способ «ПИД уровня»
    xAckAll       : BOOL;           // импульс: квитировать все тревоги станции, LIC101 и устройств
    xResetAll     : BOOL;           // импульс: общий сброс (как HS501)
    xSilence      : BOOL;           // импульс: выключить сирену (как HS502)
    xExportLog    : BOOL;           // импульс: выгрузить журнал в CSV (04 §19.2)
    xRevertCfg    : BOOL;           // импульс: откатить записанные уставки к действующей копии (08 §14, вопрос 2)
    wAckReq       : WORD;           // маска: квитировать тревоги станции, бит slot - 1
    wShelveReq    : WORD;           // маска: отложить на astAlarm[slot].tShelveMax
    wUnshelveReq  : WORD;           // маска: вернуть отложенные
    udiAckId      : UDINT;          // квитировать тревогу по номеру (таблица HMI); 0 — нет; сбрасывается в 0
    udiShelveId   : UDINT;          // отложить тревогу любого источника на её tShelveMax; 0 — нет (08 §14, вопрос 1)
    udiUnshelveId : UDINT;          // вернуть отложенную тревогу по номеру; 0 — нет
END_STRUCT
END_TYPE
