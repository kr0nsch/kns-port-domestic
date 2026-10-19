// Выход по старшинству (контракт 2.6, 17.5): нет корректной Cfg > OutOfService > слежение >
// Manual > Auto с негодной PV > Auto. Вне Auto интегратор предустанавливается I := u - P - D (при
// возврате в Auto v = u, рывка нет). Auto: пределы, ограничение скорости, обратный расчёт
// I += Kp·dt/Ti·e' + MIN(dt/Tt, 1)·(u_aw - v), u_aw — выход ФБ или rOutAct_pct (xUseOutAct).
// Пишет rOut_pct, xSatHigh, xSatLow. Значение оператора — параметром (VAR_IN_OUT не трогает, R2)
METHOD PROTECTED SelectOutput
VAR_INPUT
    xCalcNow       : BOOL;    // в этом вызове был расчёт (CalcStep)
    xInit          : BOOL;    // расчёт — шаг инициализации
    lrStep_s       : LREAL;   // dt расчёта, с
    rManualOut_pct : REAL;    // stCmd.rManualOut_pct: выход оператора
END_VAR
VAR
    lrOutMin_pct : LREAL;     // нижний предел выхода
    lrOutMax_pct : LREAL;     // верхний предел выхода
    lrULim_pct   : LREAL;     // LIMIT(OutMin, v, OutMax)
    lrUAw_pct    : LREAL;     // выход для обратного расчёта (u или rOutAct_pct)
    lrKp         : LREAL;     // Kp
    lrTi_s       : LREAL;     // Ti
    lrTd_s       : LREAL;     // Td
    lrTt_s       : LREAL;     // постоянная слежения anti-windup
END_VAR
