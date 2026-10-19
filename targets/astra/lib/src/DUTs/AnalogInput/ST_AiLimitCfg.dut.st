// Назначение: параметры одной уставки (FB_LimitMonitor, astLimit[i] аналогового входа).
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_LimitMonitor.md
{attribute 'qualified_only'}
TYPE ST_AiLimitCfg :
STRUCT
    xEnable      : BOOL := FALSE;   // уставка включена
    rSetpoint_eu : REAL := 0.0;     // уставка, инж. ед.
    rHyst_eu     : REAL := 0.0;     // гистерезис, инж. ед., >= 0
    tOnDelay     : TIME := T#0S;    // задержка срабатывания флага
    tOffDelay    : TIME := T#0S;    // задержка снятия флага
END_STRUCT
END_TYPE
