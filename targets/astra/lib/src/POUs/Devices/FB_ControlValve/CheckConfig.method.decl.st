// Проверка конфигурации: биты wCfgErr регулирующего клапана (CV_CFG_*). Только считает, ничего не
// меняет. Неконечные значения (NaN, ±Inf) проверяются отдельно: сравнения с NaN ложны
METHOD PROTECTED CheckConfig : WORD
VAR_IN_OUT CONSTANT
    stCfgIn : ST_ControlValveCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr : WORD;                    // непройденные проверки
END_VAR
