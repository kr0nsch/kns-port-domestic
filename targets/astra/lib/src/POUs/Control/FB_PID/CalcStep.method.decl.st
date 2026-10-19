// Шаг расчёта (контракт 17.4): рампа задания; ошибка со знаком действия в % диапазона PV; зона
// нечувствительности без скачка на границе (e' = e - DB·SIGN(e)); P = Kp·e'; D по измерению с
// фильтром Tf = Td/N (обратная разность Эйлера, устойчива при любом dt; в шаге инициализации
// D := 0); PV_prev := PV; v = P + I + D. Работает только с внутренним состоянием, stCfgLkg и
// входом rPv_eu (VAR_IN_OUT не трогает, R2)
METHOD PROTECTED CalcStep
VAR_INPUT
    xInit     : BOOL;    // шаг инициализации: D := 0
    lrStep_s  : LREAL;   // dt, с (0 в шаге инициализации)
    xSpFollow : BOOL;    // задание сразу равно цели (слежение задания за PV в Manual)
END_VAR
VAR
    lrPv_eu  : LREAL;    // PV этого вызова
    lrSign   : LREAL;    // +1 обратное действие, -1 прямое
    lrScale  : LREAL;    // % диапазона PV на инж. ед.
    lrE_pct  : LREAL;    // ошибка до зоны нечувствительности
    lrDb_pct : LREAL;    // зона нечувствительности
    lrKp     : LREAL;    // Kp
    lrTd_s   : LREAL;    // Td
    lrTf_s   : LREAL;    // постоянная фильтра Д: Td / N
END_VAR
