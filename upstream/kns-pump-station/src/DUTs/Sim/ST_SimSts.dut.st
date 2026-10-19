// Назначение: состояние модели (GVL_Sim.stSimSts, только чтение): истинный уровень, потоки,
//             частоты и токи насосов, время суток, ливни, перелив, счётчик изменений инъекций.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.3
{attribute 'qualified_only'}
TYPE ST_SimSts :
STRUCT
    rLevel_m         : REAL;        // истинный уровень
    rInflow_m3h      : REAL;
    rOutflow_m3h     : REAL;
    arPumpFlow_m3h   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;
    rHead_m          : REAL;
    arFreq_Hz        : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;
    arCurrent_A      : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;
    rTimeOfDay_h     : REAL;
    udiDay           : UDINT;
    xStormActive     : BOOL;
    rStormInflow_m3h : REAL;
    udiOverflow_s    : UDINT;       // время перелива (время контура)
    rTimeScaleAct    : REAL;
    lrSimTime_s      : LREAL;
    xRunning         : BOOL;        // модель работает
    udiFaultSeq      : UDINT;       // +1 при каждом изменении stFaultInj; по нему PRG_Station пишет событие 101021
END_STRUCT
END_TYPE
