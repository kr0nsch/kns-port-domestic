// Ограничение скорости в LREAL (рампа задания и ограничение скорости выхода): значение движется
// от lrCurrent к lrTarget не быстрее lrRate ед./с за шаг lrStep_s. Скорость <= 0 — сразу к
// цели (в том числе в шаге инициализации); шаг <= 0 при заданной скорости — без изменения.
// F_RateLimit не подходит: вход и результат REAL, приращения рампы меньше шага REAL теряются
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED RateStep : LREAL
VAR_INPUT
    lrCurrent : LREAL;   // текущее значение
    lrTarget  : LREAL;   // цель
    lrRate    : LREAL;   // предел скорости, ед./с; <= 0 — без ограничения
    lrStep_s  : LREAL;   // шаг времени, с
END_VAR
