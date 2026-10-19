// Проверка конфигурации: биты wCfgErr арматуры (VLV_CFG_*). Только считает, ничего не меняет
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckConfig : WORD
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfgIn : ST_ValveCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr      : WORD;        // непройденные проверки
    xMotor    : BOOL;        // электропривод
    xSolenoid : BOOL;        // соленоид любого вида
END_VAR
