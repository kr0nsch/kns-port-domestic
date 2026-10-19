// Назначение: реакция регулирующего клапана на отказ.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_ControlValve.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_CvFaultAction :
(
    Hold    := 0,   // удерживать положение
    SafePos := 1    // в rSafePos_pct без рампы
) INT;
END_TYPE
