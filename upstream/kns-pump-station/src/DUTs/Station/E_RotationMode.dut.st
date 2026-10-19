// Назначение: режим чередования насосов (04 §8.1, 18.2 № 14).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_RotationMode :
(
    RunHours := 1,   // по моточасам: меньше RunSeconds, затем меньше Starts, затем меньший номер
    Cyclic   := 2,   // по кругу: следующий после stStationRetain.uiNextLead
    Fixed    := 3    // без чередования: Н1, Н2, Н3
) INT;
END_TYPE
