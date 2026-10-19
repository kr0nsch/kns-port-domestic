// Назначение: вид запорной арматуры: соленоид с пружинным возвратом или электропривод.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_ValveType :
(
    SolenoidEto := 0,   // соленоид, «под током — открыт» (НЗ клапан); без тока — закрыт
    SolenoidEtc := 1,   // соленоид, «под током — закрыт» (НО клапан); без тока — открыт
    Motorized   := 2    // электропривод: выходы «открывать»/«закрывать», стоп в промежутке
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
