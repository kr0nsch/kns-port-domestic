// Назначение: задвижка — FINAL-наследник базы с двумя интерфейсами
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
FUNCTION_BLOCK FINAL FB_Valve EXTENDS FB_DeviceBase IMPLEMENTS I_Positioner, I_Lockable
VAR_OUTPUT
    rPos_pct : REAL;
    xLocked : BOOL;
END_VAR
VAR
    rSetpoint_pct : REAL;
END_VAR
VAR CONSTANT
    POS_MAX : REAL := 100.0;
END_VAR
