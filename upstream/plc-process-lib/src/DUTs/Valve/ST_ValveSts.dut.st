// Назначение: состояние запорной арматуры для HMI/SCADA. 52 байта, 26 регистров Modbus:
//             только 16- и 32-битные поля без скрытого выравнивания.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
{attribute 'qualified_only'}
TYPE ST_ValveSts :
STRUCT
    stCommon         : ST_DeviceSts;   // 0..27
    eState           : E_ValveState;   // 28
    wInterlock       : WORD;     // 30: действующие блокировки (после маски)
    wPermitMissing   : WORD;     // 32: недостающие разрешения для текущего направления
    uiFirstOut       : UINT;     // 34: первопричина блокировки; NO_FIRST_OUT — нет
    uiTravelRemain_s : UINT;     // 36: до таймаута хода, с
    wReserve         : WORD;     // 38: выравнивание следующего 32-битного поля
    udiCycles        : UDINT;    // 40: циклов «открыто» всего
    udiCyclesMaint   : UDINT;    // 44: с последнего ТО
    rActTime_h       : REAL;     // 48: время работы привода, ч
END_STRUCT
END_TYPE
