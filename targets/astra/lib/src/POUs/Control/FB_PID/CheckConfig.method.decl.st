// Проверка конфигурации: биты wCfgErr (карта битов docs/fb/FB_PID.md). Неконечное значение
// REAL-параметра даёт бит его группы. Только считает, ничего не меняет
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckConfig : WORD
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfgIn : ST_PidCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr : WORD;           // непройденные проверки
END_VAR
