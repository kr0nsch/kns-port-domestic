// Проверка конфигурации: биты wCfgErr (карта битов docs/fb/FB_PID.md). Неконечное значение
// REAL-параметра даёт бит его группы. Только считает, ничего не меняет
METHOD PROTECTED CheckConfig : WORD
VAR_IN_OUT CONSTANT
    stCfgIn : ST_PidCfg;   // проверяемая конфигурация
END_VAR
VAR
    wErr : WORD;           // непройденные проверки
END_VAR
