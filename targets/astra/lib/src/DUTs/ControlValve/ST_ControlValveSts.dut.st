// Назначение: состояние регулирующего клапана для HMI/SCADA. 52 байта, 26 регистров Modbus:
//             только 16- и 32-битные поля без скрытого выравнивания.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_ControlValve.md
{attribute 'qualified_only'}
TYPE ST_ControlValveSts :
STRUCT
    stCommon       : ST_DeviceSts;   // 0..27
    rPosSp_pct     : REAL;   // 28: задание после пределов, до рампы
    rOut_pct       : REAL;   // 32: задание положения, % хода
    rOut_mA        : REAL;   // 36: на AO с учётом инверсии
    rPosFb_pct     : REAL;   // 40: ОС положения
    rDeviation_pct : REAL;   // 44: rOut_pct − rPosFb_pct
    wInterlock     : WORD;   // 48: действующие блокировки
    uiFirstOut     : UINT;   // 50: первопричина блокировки; NO_FIRST_OUT — нет
END_STRUCT
END_TYPE
