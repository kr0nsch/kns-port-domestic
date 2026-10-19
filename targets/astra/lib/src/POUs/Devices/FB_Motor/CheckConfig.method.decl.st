// Проверка конфигурации двигателя: биты 0–3 wCfgErr (13.9). Только считает, ничего не меняет.
// FB_MotorVfd переопределяет: SUPER^.CheckConfig OR биты ПЧ 8–11
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckConfig : WORD
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfgIn : ST_MotorCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr : WORD;             // непройденные проверки
END_VAR
