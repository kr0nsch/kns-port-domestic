// Назначение: режим станции (04 §3). Другое значение в retain санитизируется в Manual
//             сравнениями (FB_StationMode, правило L4 контракта plc-process-lib).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_StationMode :
(
    Auto   := 1,   // «Автомат»: насосами управляет логика станции
    Manual := 2    // «Ручной»: насосами управляет оператор с HMI, блокировки действуют
) INT;
END_TYPE
