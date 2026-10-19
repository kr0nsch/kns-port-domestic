// Запрос режима для станционной логики, как бит stCmd: Auto, Manual, OutOfService — TRUE (запрос
// выполнит ProcessMode ближайшего вызова, результат — в eCmdResult); Local и прочее — FALSE.
// Имя параметра не eMode: оно затенило бы переменную базы (L3)
METHOD PUBLIC RequestMode : BOOL
VAR_INPUT
    eNewMode : E_DeviceMode;   // требуемый режим
END_VAR
