// Назначение: выбранный способ регулирования (04 §3.2, 18.2 № 1). Другое значение в retain
//             санитизируется в Stepped.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ControlMethod :
(
    Stepped  := 1,   // ступенчатое по уровням (04 §6)
    LevelPid := 2    // поддержание уровня ПИД LIC101 (04 §7)
) INT;
END_TYPE
