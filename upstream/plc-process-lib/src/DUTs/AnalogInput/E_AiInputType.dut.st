// Назначение: смысл входа rIn аналогового входа и применимость проверки NAMUR NE 43.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_AnalogInput.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_AiInputType :
(
    MilliAmp := 0,   // rIn в мА, 4–20, проверка NE 43
    Norm420  := 1,   // rIn 0..1 соответствует 4–20 мА; NE 43 по пересчёту I = 4 + 16·rIn
    Norm01   := 2,   // rIn 0..1 без NE 43 (0–10 В и т. п.)
    Eng      := 3,   // rIn уже в инж. ед. (Modbus REAL, расчёт); NE 43 не применяется
    Raw      := 4    // rIn в единицах канала (отсчёты АЦП, целое из Modbus): rRawLo_cnt..rRawHi_cnt
) INT;
END_TYPE
