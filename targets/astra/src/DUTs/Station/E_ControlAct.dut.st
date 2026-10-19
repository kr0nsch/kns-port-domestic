// Назначение: действующее управление насосами (04 §4), поле stStationSts.eControlAct.
//             Старшинство в «Автомате»: PowerLost > Restart > DryRunStop > Float > Emergency >
//             LevelPid > Stepped.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ControlAct :
(
    Manual     := 0,   // станция в «Ручном»: запросов нет, только блокировки
    Stepped    := 1,   // ступенчатое регулирование
    LevelPid   := 2,   // ПИД уровня и подключение по нагрузке
    Float      := 3,   // резервное управление по поплавкам (LT101 недостоверен)
    Emergency  := 4,   // аварийно высокий уровень: все доступные насосы
    DryRunStop := 5,   // защита «сухой ход»: запросы сняты
    PowerLost  := 6,   // нет напряжения на вводе
    Restart    := 7    // задержка после старта или восстановления питания, последовательный пуск
) INT;
END_TYPE
