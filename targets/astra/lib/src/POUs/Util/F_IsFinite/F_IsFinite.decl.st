// Назначение: TRUE, если REAL — конечное правдоподобное число. FALSE для NaN и ±Inf
//             (все биты экспоненты = 1, проверка по битам через U_RealBits — не зависит от
//             оптимизатора) и для |rIn| > REAL_SANE_MAX (мусор: перепутан порядок слов Modbus).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/Functions.md
FUNCTION F_IsFinite : BOOL
VAR_INPUT
    rIn : REAL;            // проверяемое значение
END_VAR
VAR
    uBits : U_RealBits;    // биты значения
END_VAR
