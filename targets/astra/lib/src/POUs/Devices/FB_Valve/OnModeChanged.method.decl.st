// Хук смены режима: сначала база (SUPER^); переход в Manual — цель := текущее направление или
// положение (арматура не дёргается); вход в OutOfService снимает зафиксированные отказы и
// первопричину. VAR_IN_OUT устройства не трогает (R2)
METHOD PROTECTED OnModeChanged
VAR_INPUT
    eOld : E_DeviceMode;   // режим до смены
    eNew : E_DeviceMode;   // новый режим
END_VAR
