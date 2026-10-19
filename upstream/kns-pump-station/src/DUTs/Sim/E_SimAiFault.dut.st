// Назначение: инъекция отказа аналогового датчика 4–20 мА в модели (NAMUR NE 43): обрыв,
//             токи отказа и выхода из диапазона, замерзание, принудительный ток.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.3; docs/06_PMI.md, раздел 5.4
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_SimAiFault :
(
    None := 0,          // нет инъекции: ток по измеренному значению
    WireBreak := 1,     // обрыв линии: 0 мА
    FailLow := 2,       // отказ снизу: SIM_MA_FAIL_LOW (3,0 мА)
    FailHigh := 3,      // отказ сверху: SIM_MA_FAIL_HIGH (22 мА)
    UnderRange := 4,    // ниже диапазона: SIM_MA_UNDER_RANGE (3,7 мА)
    OverRange := 5,     // выше диапазона: SIM_MA_OVER_RANGE (20,8 мА)
    Freeze := 6,        // замерзание: последнее значение тока
    Forced := 7         // принудительный ток arAiForced_mA
) INT;
END_TYPE
