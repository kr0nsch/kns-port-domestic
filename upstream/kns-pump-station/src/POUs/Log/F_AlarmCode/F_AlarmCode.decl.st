// Назначение: код записи журнала по номеру (CSV, DESIGN, раздел 9.2): устройство — <TAG>.<SUFFIX> по
//             GVL_DeviceList (номер = dev_no · 10 + слот, суффиксы слотов — таблица контракта plc-process-lib,
//             раздел 19), станция — KNS1.<SUFFIX> (100000 + slot, 04 §15), LIC101 — LIC101.<SUFFIX> (100100 +
//             слот), событие станции — KNS1.E<код> (101000 + код, 04 §16). Неизвестный номер — его цифры.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 9.2
FUNCTION F_AlarmCode : STRING(GVL_Const.LOG_CODE_LEN)
VAR_INPUT
    udiId : UDINT;                  // номер тревоги или события
END_VAR
VAR
    uiDevNo : UINT;                 // номер устройства
    uiSlot  : UINT;                 // слот тревоги
    uiI     : UINT;                 // индекс GVL_DeviceList
    sSuffix : STRING(GVL_Const.LOG_SUFFIX_LEN);   // суффикс слота
    eType   : PL.E_DeviceType;      // тип устройства
END_VAR
VAR CONSTANT
    ID_PER_DEVICE : UDINT := 10;    // номер тревоги устройства = dev_no · 10 + слот (контракт 20.5)
    STATION_TAG   : STRING(GVL_Const.LOG_SUFFIX_LEN) := 'KNS1';
    PID_TAG       : STRING(GVL_Const.LOG_SUFFIX_LEN) := 'LIC101';
    EVENT_PREFIX  : STRING(GVL_Const.LOG_SUFFIX_LEN) := 'E';
    AI_SUFFIX  : ARRAY[0..GVL_Const.ALM_SLOT_MAX] OF STRING(GVL_Const.LOG_SUFFIX_LEN) :=
        ['HH', 'H', 'L', 'LL', 'FAIL', 'OOR', '', ''];
    DI_SUFFIX  : ARRAY[0..GVL_Const.ALM_SLOT_MAX] OF STRING(GVL_Const.LOG_SUFFIX_LEN) :=
        ['ALM', 'FAIL', '', '', '', '', '', ''];
    MOT_SUFFIX : ARRAY[0..GVL_Const.ALM_SLOT_MAX] OF STRING(GVL_Const.LOG_SUFFIX_LEN) :=
        ['FTS', 'FBL', 'FTP', 'UCR', 'EXT', 'ILK', 'COM', 'SPD'];
    VLV_SUFFIX : ARRAY[0..GVL_Const.ALM_SLOT_MAX] OF STRING(GVL_Const.LOG_SUFFIX_LEN) :=
        ['FTO', 'FTC', 'BLS', 'PLS', 'TRQ', 'EXT', 'ILK', ''];
    CV_SUFFIX  : ARRAY[0..GVL_Const.ALM_SLOT_MAX] OF STRING(GVL_Const.LOG_SUFFIX_LEN) :=
        ['DEV', 'FBF', 'POS', 'ILK', '', '', '', ''];
    PID_SUFFIX : ARRAY[0..GVL_Const.ALM_SLOT_MAX] OF STRING(GVL_Const.LOG_SUFFIX_LEN) :=
        ['PVF', '', '', '', '', '', '', ''];
    // тревоги станции по slot 1…13 (E_StationAlarm, 04 §15)
    STN_SUFFIX : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF STRING(GVL_Const.LOG_SUFFIX_LEN) :=
        ['EHL', 'DRY', 'LACK', 'NORES', 'ATS', 'FLOAT', 'LDEV', 'STEP', 'NOAUTO', 'UL1', 'UL2', 'UL3', 'SIM'];
END_VAR
