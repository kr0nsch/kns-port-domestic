// Назначение: двигатель — наследник базы: пуск, сброс через SUPER^, счёт пусков
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
FUNCTION_BLOCK FB_Motor EXTENDS FB_DeviceBase
VAR_INPUT
    stCmd : ST_MotorCmd;
END_VAR
VAR_OUTPUT
    xRun : BOOL;
END_VAR
VAR
    uiStarts : UINT;
    fbCounter : FB_Counter;
END_VAR
