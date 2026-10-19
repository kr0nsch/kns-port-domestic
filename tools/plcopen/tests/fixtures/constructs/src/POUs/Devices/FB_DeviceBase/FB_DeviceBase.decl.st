// Назначение: абстрактная база устройств — режим, отказ, квитирование
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
{attribute 'reflection'}
FUNCTION_BLOCK ABSTRACT FB_DeviceBase IMPLEMENTS I_Device
VAR_INPUT
    xReset : BOOL;
END_VAR
VAR_OUTPUT
    xFault : BOOL;
END_VAR
VAR
    eModeInt : E_Mode := E_Mode.OutOfService;
    {attribute 'hide'}
    xFaultInt : BOOL;
END_VAR
VAR_STAT
    uiInstances : UINT;
END_VAR
