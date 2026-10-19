// Шаг 5: команды HMI xClose > xOpen > xStop и xResetMaint; результат каждой — SetCmdResult. В Auto
// принятая команда переводит в Manual (оператор вмешался — автомат отпущен). Структуры — параметрами
// VAR_IN_OUT: метод не обращается к VAR_IN_OUT экземпляра (R2).
// Шаг тела FB_Valve; внутренний: PROTECTED (правило L5 контракта), имя зарезервировано для наследников
METHOD PROTECTED HandleCommands
VAR_IN_OUT
    stValveCmd : ST_ValveCmd;       // stCmd устройства: импульсы сбрасываются
    stValveRet : ST_DeviceRetain;   // stRetain устройства: режим, счётчики «с ТО»
END_VAR
VAR
    eCmdTgt : E_ValveState := E_ValveState.Intermediate;   // цель команды; Intermediate — стоп
    eResCmd : E_CmdResult := E_CmdResult.None;             // результат команды
END_VAR
