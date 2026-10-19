// Назначение: индексы слотов тревог ПИД-регулятора. Нестрогое перечисление: им
//             индексируются массивы.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_PID.md
{attribute 'qualified_only'}
TYPE E_PidAlarm :
(
    PvInvalid := 0   // PV недостоверна в Auto
) UINT;
END_TYPE
