// Хук смены режима: сначала база (SUPER^); рампа предустанавливается текущим выходом (без рывка);
// вход в OutOfService снимает фиксацию рассогласования и первопричину. VAR_IN_OUT устройства не
// трогает (R2)
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED OnModeChanged
VAR_INPUT
    eOld : E_DeviceMode;   // режим до смены
    eNew : E_DeviceMode;   // новый режим
END_VAR
