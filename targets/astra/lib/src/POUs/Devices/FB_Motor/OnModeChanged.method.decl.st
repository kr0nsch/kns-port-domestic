// Хук смены режима (13.4): сначала база (SUPER^), затем безударность — Auto → Manual: ручная
// защёлка := команда работы (работающий насос продолжает работать); Local или OutOfService →
// Auto/Manual: защёлка := ОС (запущенный по месту двигатель продолжает работать в Manual). Вход в
// OutOfService снимает зафиксированные отказы и первопричину. VAR_IN_OUT устройства не трогает (R2)
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED OnModeChanged
VAR_INPUT
    eOld : E_DeviceMode;   // режим до смены
    eNew : E_DeviceMode;   // новый режим
END_VAR
