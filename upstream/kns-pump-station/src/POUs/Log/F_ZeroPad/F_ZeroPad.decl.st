// Назначение: десятичная запись числа с ведущими нулями до uiDigits знаков (поля даты и времени CSV журнала);
//             число длиннее uiDigits — без обрезки.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 9.2
FUNCTION F_ZeroPad : STRING(GVL_Const.LOG_NUM_LEN)
VAR_INPUT
    udiValue : UDINT;               // число
    uiDigits : UINT;                // знаков не меньше
END_VAR
VAR
    uiI : UINT;                     // номер добавляемого нуля
END_VAR
