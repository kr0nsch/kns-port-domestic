// Номер суток для часов модели lrHours (целая часть lrHours / 24); отрицательное или неконечное — 0
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PRIVATE (C3)
METHOD PRIVATE DayOf : UDINT
VAR_INPUT
    lrHours : LREAL;        // часы модели от полуночи суток 0
END_VAR
VAR
    lrDays  : LREAL;        // сутки с дробной частью
    udiDays : UDINT;        // округлённые сутки
END_VAR
