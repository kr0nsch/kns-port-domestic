// Добавить к rInflow_m3h приток ливня (трапеция: рост 15 %, полка 50 %, спад 35 %) в момент lrClock_h;
// ливень идёт — xActive. Вне [начало, начало + длительность) ливень ничего не добавляет
METHOD PRIVATE AddStorm
VAR_INPUT
    lrStartAt_h : LREAL;    // начало ливня по часам модели
    tDur        : TIME;     // длительность
    rPeak       : REAL;     // пик, м³/ч
END_VAR
VAR
    lrTau_s  : LREAL;       // время от начала ливня
    lrDur_s  : LREAL;       // длительность, с
    lrRise_s : LREAL;       // конец роста
    lrFall_s : LREAL;       // начало спада
END_VAR
