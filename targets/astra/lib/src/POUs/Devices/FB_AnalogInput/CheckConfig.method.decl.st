// Проверка конфигурации: биты wCfgErr аналогового входа (карта — docs/fb/FB_AnalogInput.md). Только
// считает, ничего не меняет. Сравнения записаны так, чтобы NaN давал ошибку (NOT (x >= a AND x <= b))
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckConfig : WORD
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfgIn : ST_AnalogInputCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr    : WORD;                // непройденные проверки
    uiIdx   : UINT;                // индекс уставки: HH, H, L, LL
    stLim   : ST_AiLimitCfg;       // копия уставки: короче условия проверок
    xPrev   : BOOL;                // была включённая уставка старше текущей
    rPrevSp : REAL;                // её значение, инж. ед.
    rSpan   : REAL;                // диапазон шкалы, инж. ед.
END_VAR
