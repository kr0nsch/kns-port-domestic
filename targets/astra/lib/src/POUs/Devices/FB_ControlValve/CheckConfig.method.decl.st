// Проверка конфигурации: биты wCfgErr регулирующего клапана (CV_CFG_*). Только считает, ничего не
// меняет. Неконечные значения (NaN, ±Inf) проверяются отдельно: сравнения с NaN ложны
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckConfig : WORD
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfgIn : ST_ControlValveCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr : WORD;                    // непройденные проверки
END_VAR
