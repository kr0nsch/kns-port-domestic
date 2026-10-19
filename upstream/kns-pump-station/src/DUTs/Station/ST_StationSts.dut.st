// Назначение: состояние станции (GVL_Station.stStationSts) для HMI, OPC UA и MQTT: только 16- и
//             32-битные поля, 72 байта (тест StationStsSizeIs72), 04 §19.3.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
TYPE ST_StationSts :
STRUCT
    eMode             : E_StationMode;
    eMethod           : E_ControlMethod;
    eControlAct       : E_ControlAct;
    eNe107            : PL.E_Ne107Status;   // F — LACK; S — FLOAT, STEP, LDEV, NORES; C — «Ручной», имитация,
                                            // wCfgErr; M — ТО насоса
    wState            : WORD;               // биты STN_ST_*
    wCfgErr           : WORD;               // биты STN_CFG_*
    aeRole            : ARRAY[1..3] OF E_PumpRole;
    uiPumpsRequired   : UINT;
    uiPumpsRunning    : UINT;
    uiPumpsAvailable  : UINT;
    uiLeadPump        : UINT;               // 0 — нет
    uiSeqRemain_s     : UINT;
    eCmdResult        : PL.E_CmdResult;     // результат последней команды станции
    uiCmdSeq          : UINT;               // +1 на каждую обработанную команду
    wAlmActive        : WORD;               // тревоги станции, бит slot - 1
    wAlmUnack         : WORD;
    wAlmShelved       : WORD;               // дополнение: Shelved, SuppressedByDesign, OutOfService
    ePrioUnack        : PL.E_AlarmPriority; // высший неквитированный по всем источникам (баннер)
    auiUnack          : ARRAY[1..4] OF UINT;// неквитированных Low…Critical
    eLogExport        : E_LogExportState;   // дополнение: состояние выгрузки CSV
    wReserve          : WORD;               // выравнивание: дальше 32-битные поля
    rLevel_m          : REAL;               // уровень, по которому работает станция
    rLevelSp_m        : REAL;               // действующее задание уровня
    rSpeedSp_pct      : REAL;               // общее задание частоты насосам
    udiEventSeq       : UDINT;              // номер последней записи журнала
    udiLogOverwritten : UDINT;              // затёрто записей журнала
END_STRUCT
END_TYPE
