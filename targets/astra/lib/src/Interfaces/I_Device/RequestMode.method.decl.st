// Запрос режима: Auto, Manual, OutOfService — как команда stCmd; Local и прочее — FALSE.
// Имя параметра не eMode: оно затенило бы переменную базы (L3)
METHOD RequestMode : BOOL
VAR_INPUT
    eNewMode : E_DeviceMode;   // требуемый режим
END_VAR
