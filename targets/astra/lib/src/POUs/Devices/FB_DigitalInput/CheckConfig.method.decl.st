// Проверка конфигурации: биты wCfgErr дискретного входа (карта — docs/fb/FB_DigitalInput.md). Только
// считает, ничего не меняет
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckConfig : WORD
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfgIn : ST_DigitalInputCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr : WORD;                    // непройденные проверки
END_VAR
