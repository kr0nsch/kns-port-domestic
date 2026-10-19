// Назначение: шаг генератора псевдослучайных чисел xorshift32 (G. Marsaglia, «Xorshift RNGs»,
//             Journal of Statistical Software, 2003; сдвиги 13, 17, 5): x ^= x << 13; x ^= x >> 17;
//             x ^= x << 5. Из нуля генератор не выходит — вызывающий не подаёт 0 (FB_StormGenerator
//             заменяет нулевое начальное состояние на SIM_XS_ZERO_STATE).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 11.2
FUNCTION F_Xorshift32 : DWORD
VAR_INPUT
    dwState : DWORD;    // текущее состояние
END_VAR
VAR
    dwX : DWORD;        // промежуточное значение
END_VAR
