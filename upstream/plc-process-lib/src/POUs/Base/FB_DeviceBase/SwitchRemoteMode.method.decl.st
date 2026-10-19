// Смена дистанционного режима логикой устройства («Стоп» в Auto → Manual, снятие подмены AI/DI по
// времени, ПИД ShedToManual): запоминается в stRetain; если устройство в дистанционном режиме —
// режим меняется сразу, с хуком THIS^.OnModeChanged. Значения кроме Auto и Manual не принимаются
METHOD PROTECTED SwitchRemoteMode
VAR_INPUT
    eNew : E_DeviceMode;          // Auto или Manual
END_VAR
VAR_IN_OUT
    stRetain : ST_DeviceRetain;   // дистанционный режим (AI/DI — stModeMem)
END_VAR
VAR
    eModeOld : E_DeviceMode := E_DeviceMode.Manual;   // режим до смены
END_VAR
