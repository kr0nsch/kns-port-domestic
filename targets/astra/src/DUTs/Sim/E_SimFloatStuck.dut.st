// Назначение: инъекция залипания поплавкового выключателя в модели.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.3; docs/06_PMI.md, раздел 5.4
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_SimFloatStuck :
(
    None := 0,          // нет инъекции: контакт по уровню
    StuckNormal := 1,   // контакт не срабатывает (НЗ остаётся замкнутым)
    StuckTripped := 2   // сработал и не возвращается; то же — обрыв цепи НЗ-контакта
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
