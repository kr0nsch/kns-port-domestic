// Назначение: реакция ПИД-регулятора в Auto на недостоверную PV.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_PID.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_PidPvFailAction :
(
    Hold         := 0,   // удерживать выход; когда PV снова годна — продолжить без рывка
    SafeOut      := 1,   // выход := rSafeOut_pct; возврат без рывка
    ShedToManual := 2    // перейти в Manual с текущим выходом; в Auto возвращает оператор
) INT;
END_TYPE
