// Проверка конфигурации: биты wCfgErr арматуры (VLV_CFG_*). Только считает, ничего не меняет
METHOD PROTECTED CheckConfig : WORD
VAR_IN_OUT CONSTANT
    stCfgIn : ST_ValveCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr      : WORD;        // непройденные проверки
    xMotor    : BOOL;        // электропривод
    xSolenoid : BOOL;        // соленоид любого вида
END_VAR
