// Проверка конфигурации: биты wCfgErr дискретного входа (карта — docs/fb/FB_DigitalInput.md). Только
// считает, ничего не меняет
METHOD PROTECTED CheckConfig : WORD
VAR_IN_OUT CONSTANT
    stCfgIn : ST_DigitalInputCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr : WORD;                    // непройденные проверки
END_VAR
