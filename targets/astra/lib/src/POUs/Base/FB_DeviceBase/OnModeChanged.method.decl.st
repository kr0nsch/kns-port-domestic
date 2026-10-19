// Виртуальный хук смены режима, в базе пуст. Вызывается только как THIS^.OnModeChanged(...) из
// ProcessMode и SwitchRemoteMode, в том числе в первом вызове, если режим из stRetain отличается
// от начального Manual (наследник отличает этот случай по xFirstCall). Наследник переопределяет с
// той же сигнатурой и PROTECTED и в начале вызывает SUPER^.OnModeChanged(eOld := eOld, eNew := eNew).
// Хук НЕ ДОЛЖЕН трогать VAR_IN_OUT устройства (R2)
METHOD PROTECTED OnModeChanged
VAR_INPUT
    eOld : E_DeviceMode;   // режим до смены
    eNew : E_DeviceMode;   // новый режим
END_VAR
