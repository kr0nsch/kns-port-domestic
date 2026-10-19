// Назначение: направление действия ПИД-регулятора.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_PID.md
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_PidAction :
(
    Reverse := 0,   // обратное: PV растёт — выход падает (e = SP − PV); нагрев, подача
    Direct  := 1    // прямое: PV растёт — выход растёт (e = PV − SP); уровень → скорость откачки
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
