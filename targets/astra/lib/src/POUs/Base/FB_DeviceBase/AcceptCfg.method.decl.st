// Шаг 2 цикла: результат CheckConfig. wErr = 0 — конфигурация корректна: TRUE, вызывающий копирует
// stCfgLkg := stCfg; иначе логика работает по последней корректной копии (LKG)
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED AcceptCfg : BOOL
VAR_INPUT
    wErr : WORD;   // биты непройденных проверок (карта wCfgErr устройства)
END_VAR
