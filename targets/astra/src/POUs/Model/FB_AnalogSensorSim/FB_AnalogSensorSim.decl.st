// Назначение: датчик 4–20 мА в модели: ток = 4 + 16·(x − min)/(max − min) с насыщением
//             преобразователя на границах измерения NE 43 (3,8…20,5 мА), затем инъекция отказа
//             E_SimAiFault: обрыв (0 мА), токи отказа и выхода из диапазона SIM_MA_*, замерзание
//             (последний ток), принудительный ток. Неверная шкала или неконечное значение — ток
//             отказа снизу SIM_MA_FAIL_LOW (как у неисправного преобразователя).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 11.2; docs/06_PMI.md, раздел 5.4
FUNCTION_BLOCK FB_AnalogSensorSim
VAR_INPUT
    rValue     : REAL;              // измеряемая величина, инж. ед.
    rRangeLo   : REAL;              // нижняя граница шкалы (4 мА)
    rRangeHi   : REAL;              // верхняя граница шкалы (20 мА)
    eFault     : E_SimAiFault;      // инъекция
    rForced_mA : REAL;              // ток при Forced
END_VAR
VAR_OUTPUT
    rCurrent_mA : REAL;             // ток в линии — вход модуля AI (GVL_IO.r<TAG>_mA)
END_VAR
VAR
    rMeas_mA : REAL;                // ток исправного преобразователя
END_VAR
