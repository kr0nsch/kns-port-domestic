// Назначение: значение дискретного входа при отказе канала.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_DigitalInput.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_DiFailValue :
(
    HoldLast   := 0,   // удерживать последнее значение
    ForceFalse := 1,
    ForceTrue  := 2    // для защитных сигналов: отказ канала = сработал
) INT;
END_TYPE
