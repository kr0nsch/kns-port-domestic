// Назначение: шаг ограничителя скорости изменения: значение движется от rCurrent к rTarget
//             не быстрее rRateUp_ups (рост) и rRateDown_ups (спад) инж. ед. в секунду за шаг
//             lrDt_s. Скорость 0 (или меньше) — без ограничения. lrDt_s <= 0 или rTarget не
//             конечно (NaN из Modbus/ПИД) — значение не меняется. Расчёт шага — в LREAL.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/Functions.md
FUNCTION F_RateLimit : REAL
VAR_INPUT
    rCurrent      : REAL;    // текущее значение (результат прошлого шага)
    rTarget       : REAL;    // цель
    rRateUp_ups   : REAL;    // предел скорости роста, инж. ед./с; <= 0 — без ограничения
    rRateDown_ups : REAL;    // предел скорости спада, инж. ед./с; <= 0 — без ограничения
    lrDt_s        : LREAL;   // шаг времени, с
END_VAR
VAR
    lrLimit : LREAL;         // достижимое за шаг значение
END_VAR
