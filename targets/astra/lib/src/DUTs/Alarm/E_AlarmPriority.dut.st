// Назначение: приоритет тревоги. None выключает тревогу: она не формируется, событий нет.
//             Значения вне перечисления FB_Alarm считает Medium.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Тревоги»
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_AlarmPriority :
(
    None     := 0,   // тревога выключена: не формируется, событий нет
    Low      := 1,
    Medium   := 2,
    High     := 3,
    Critical := 4    // резерв под аварийный уровень
) INT;
END_TYPE
