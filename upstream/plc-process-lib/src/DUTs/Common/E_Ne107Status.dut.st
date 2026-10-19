// Назначение: диагностический статус по NAMUR NE 107. Значения упорядочены по тяжести,
//             сводный статус — MAX (F_Ne107Worst). Порядок F > C > S > M принят по практике
//             агрегации — сверить с текстом NAMUR NE 107.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Общие типы»
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Ne107Status :
(
    Good                := 0,   // норма
    MaintenanceRequired := 1,   // M — требуется обслуживание
    OutOfSpecification  := 2,   // S — вне спецификации
    CheckFunction       := 3,   // C — функциональная проверка (подмена, OOS, конфигурация)
    Failure             := 4    // F — отказ
) INT;
END_TYPE
