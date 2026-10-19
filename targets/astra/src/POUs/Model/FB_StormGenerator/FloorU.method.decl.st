// Целая часть неотрицательного LREAL (LREAL_TO_UDINT округляет — поправка вниз); отрицательное — 0
METHOD PRIVATE FloorU : UDINT
VAR_INPUT
    lrValue : LREAL;        // значение, ≥ 0
END_VAR
VAR
    udiRound : UDINT;       // округлённое значение
END_VAR
