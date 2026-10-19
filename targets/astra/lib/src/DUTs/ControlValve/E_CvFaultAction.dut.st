// Назначение: реакция регулирующего клапана на отказ.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_ControlValve.md
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_CvFaultAction :
(
    Hold    := 0,   // удерживать положение
    SafePos := 1    // в rSafePos_pct без рампы
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
