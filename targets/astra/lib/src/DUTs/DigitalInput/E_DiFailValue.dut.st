// Назначение: значение дискретного входа при отказе канала.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_DigitalInput.md
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_DiFailValue :
(
    HoldLast   := 0,   // удерживать последнее значение
    ForceFalse := 1,
    ForceTrue  := 2    // для защитных сигналов: отказ канала = сработал
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
