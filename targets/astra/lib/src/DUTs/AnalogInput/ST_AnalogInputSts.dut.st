// Назначение: состояние аналогового входа для HMI/SCADA. 44 байта, 22 регистра Modbus:
//             только 16- и 32-битные поля без скрытого выравнивания.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_AnalogInput.md
{attribute 'qualified_only'}
TYPE ST_AnalogInputSts :
STRUCT
    stCommon        : ST_DeviceSts;      // 0..27
    rValue_eu       : REAL;              // 28: итоговое значение
    rValue_pct      : REAL;              // 32: % шкалы
    rIn             : REAL;              // 36: сырое значение входа
    eSignal         : E_AiSignalState;   // 40: мгновенная классификация (до задержки)
    uiSubstRemain_s : UINT;              // 42: до автоматического снятия подмены, с; 0 — подмены нет
END_STRUCT
END_TYPE
