// Назначение: параметры преобразователя частоты (поле stVfd в ST_MotorCfg); используется
//             только FB_MotorVfd.
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_MotorVfd.md
{attribute 'qualified_only'}
TYPE ST_VfdCfg :
STRUCT
    rSpeedMin_pct    : REAL := 0.0;    // мин. задание в работе, % (по данным насоса и двигателя)
    rSpeedMax_pct    : REAL := 100.0;  // макс. задание, %
    rRampUp_pctps    : REAL := 0.0;    // ограничение роста задания, %/с; 0 — нет (работают рампы ПЧ)
    rRampDown_pctps  : REAL := 0.0;    // ограничение спада задания, %/с; 0 — нет
    xFbFromComm      : BOOL := TRUE;   // ОС «в работе» — из слова состояния ПЧ (xVfdRunning); FALSE — DI xFbRun
    xCommLossIsFault : BOOL := TRUE;   // FALSE — пуск/стоп заведены проводами, по Modbus только задание
    tCommLoss        : TIME := T#3S;   // фильтр потери связи
    rSpeedDev_pct    : REAL := 10.0;   // допустимое рассогласование задание/факт; 0 — контроль выключен
    tSpeedDev        : TIME := T#10S;  // задержка рассогласования
END_STRUCT
END_TYPE
