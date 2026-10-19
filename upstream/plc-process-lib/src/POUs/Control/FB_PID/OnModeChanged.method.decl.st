// Хук смены режима: сначала база (SUPER^). Выход из OutOfService — следующий расчёт будет шагом
// инициализации (PV_prev := PV, D := 0, I := u - P): за время OOS PV и время ушли. Вход в Auto —
// предустановка I := u - P - D по последнему расчёту: v = u, переход без рывка (в Manual и при
// слежении тело держит это равенство каждый вызов). VAR_IN_OUT устройства не трогает (R2)
METHOD PROTECTED OnModeChanged
VAR_INPUT
    eOld : E_DeviceMode;   // режим до смены
    eNew : E_DeviceMode;   // новый режим
END_VAR
