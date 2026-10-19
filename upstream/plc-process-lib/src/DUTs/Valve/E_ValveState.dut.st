// Назначение: состояние запорной арматуры.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_ValveState :
(
    Unknown      := 0,   // нет концевиков и нет истории
    Closed       := 1,
    Opening      := 2,
    Open         := 3,
    Closing      := 4,
    Intermediate := 5,   // остановлена в промежутке
    Reversing    := 6,   // пауза перед сменой направления
    Fault        := 7
) INT;
END_TYPE
