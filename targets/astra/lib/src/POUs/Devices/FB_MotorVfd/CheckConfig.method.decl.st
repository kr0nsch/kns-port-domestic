// Проверка конфигурации двигателя с ПЧ: биты FB_Motor (SUPER^) и биты ПЧ 8–11 (13.9). Только считает
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckConfig : WORD
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfgIn : ST_MotorCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr      : WORD;        // непройденные проверки
    stVfdChk  : ST_VfdCfg;   // параметры ПЧ проверяемой конфигурации
END_VAR
