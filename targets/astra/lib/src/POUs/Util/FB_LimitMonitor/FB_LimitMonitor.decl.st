// Назначение: одна уставка с гистерезисом, задержками срабатывания и снятия и
//             разрешением. Верхняя: флаг при значении >= уставки, снятие ниже уставки минус
//             гистерезис; нижняя — зеркально. Неконечное значение флаг не меняет. Выключенная
//             уставка или xForceOff снимают флаг сразу, без задержки.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_LimitMonitor.md
FUNCTION_BLOCK FB_LimitMonitor
VAR_INPUT
    rValue_eu  : REAL;             // контролируемое значение
    xHighLimit : BOOL;             // TRUE — верхняя уставка (HH, H), FALSE — нижняя (L, LL)
    xForceOff  : BOOL;             // TRUE — флаг FALSE сразу (отказ сигнала, OOS)
    stCfg      : ST_AiLimitCfg;    // параметры уставки
    itfTime    : I_TimeSource;     // источник времени; 0 — встроенный fbSysTime
END_VAR
VAR_OUTPUT
    xOut : BOOL;                   // после гистерезиса и задержек
    xRaw : BOOL;                   // после гистерезиса, до задержек
END_VAR
VAR
    fbDelay   : FB_Delay;          // задержки срабатывания и снятия флага
    fbSysTime : FB_SystemTime;     // запасной источник времени
END_VAR
VAR_TEMP
    itfTimeAct : I_TimeSource;     // действующий источник этого вызова
    xNewRaw    : BOOL;             // флаг после гистерезиса для конечного значения
END_VAR
