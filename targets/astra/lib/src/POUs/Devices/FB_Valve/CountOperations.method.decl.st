// Шаг 6.9: циклы «открыто» и время работы привода в stRetain (параметр VAR_IN_OUT, R2).
// Шаг тела FB_Valve; внутренний: PROTECTED (правило L5 контракта), имя зарезервировано для наследников
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CountOperations
VAR_IN_OUT
    stValveRet : ST_DeviceRetain;   // stRetain устройства
END_VAR
