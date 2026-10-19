// Назначение: доступ к битам REAL — F_IsFinite проверяет экспоненту на NaN и ±Inf без
//             сравнения r = r, результат которого зависит от оптимизатора.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/Functions.md
{attribute 'qualified_only'}
TYPE U_RealBits :
UNION
    rValue  : REAL;    // значение
    dwValue : DWORD;   // те же 32 бита (IEEE 754: знак, 8 бит экспоненты, 23 бита мантиссы)
END_UNION
END_TYPE
