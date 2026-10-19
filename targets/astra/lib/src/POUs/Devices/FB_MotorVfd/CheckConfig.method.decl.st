// Проверка конфигурации двигателя с ПЧ: биты FB_Motor (SUPER^) и биты ПЧ 8–11 (13.9). Только считает
METHOD PROTECTED CheckConfig : WORD
VAR_IN_OUT CONSTANT
    stCfgIn : ST_MotorCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr      : WORD;        // непройденные проверки
    stVfdChk  : ST_VfdCfg;   // параметры ПЧ проверяемой конфигурации
END_VAR
