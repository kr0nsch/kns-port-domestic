// Вызов одной уставки FB_LimitMonitor (шаг 7 цикла), результат — флаг уставки xOut. Уставка
// передаётся через VAR_IN_OUT: шаг уставок в теле — один вызов на уставку (AI-1). Внутренний шаг
// устройства: PROTECTED (правило L5 контракта), имя зарезервировано
METHOD PROTECTED CallLimit : BOOL
VAR_INPUT
    rLimValue : REAL;              // контролируемое значение, инж. ед.
    xHigh     : BOOL;              // TRUE — верхняя уставка (HH, H), FALSE — нижняя (L, LL)
    xOff      : BOOL;              // снять флаг сразу (OutOfService, нет Cfg, отказ)
    stLimCfg  : ST_AiLimitCfg;     // параметры уставки (stCfgLkg.astLimit[i])
END_VAR
VAR_IN_OUT
    fbLimit : FB_LimitMonitor;     // уставка afbLimit[i]
END_VAR
