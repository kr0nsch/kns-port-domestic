// Назначение: куда вести арматуру по защитной блокировке.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_ValveSafePos :
(
    Closed := 0,   // закрыть
    Open   := 1,   // открыть
    Stay   := 2    // остановить (только Motorized)
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
