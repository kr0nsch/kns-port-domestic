// Назначение: наиболее тяжёлый из двух статусов NAMUR NE 107. Значения E_Ne107Status
//             упорядочены по тяжести (Good < M < S < C < F), поэтому результат — MAX.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/Functions.md
FUNCTION F_Ne107Worst : E_Ne107Status
VAR_INPUT
    eA : E_Ne107Status;   // первый статус
    eB : E_Ne107Status;   // второй статус
END_VAR
