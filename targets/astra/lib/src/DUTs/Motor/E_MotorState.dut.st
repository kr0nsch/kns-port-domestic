// Назначение: состояние двигателя (FB_Motor, FB_MotorVfd).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Motor.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_MotorState :
(
    Stopped  := 0,
    Starting := 1,   // команда подана, ждём ОС
    Running  := 2,
    Stopping := 3,   // команда снята, ждём пропадания ОС
    Fault    := 4    // отказ: выходы сняты, ждём Reset (или восстановления связи с ПЧ)
) INT;
END_TYPE
