// Назначение: счётчик фронтов с задержкой подтверждения (без ООП, Standard: R_TRIG, TON)
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
FUNCTION_BLOCK FB_Counter
VAR_INPUT
    xIn : BOOL;                 // вход
    tConfirm : TIME := T#100MS; // задержка подтверждения
END_VAR
VAR_OUTPUT
    udiCount : UDINT;           // число фронтов
    xConfirmed : BOOL;
END_VAR
VAR_IN_OUT
    stCmd : ST_MotorCmd;
END_VAR
VAR
    fbEdge : R_TRIG;
    fbDelay : TON;
END_VAR
VAR RETAIN
    udiTotal : UDINT;
END_VAR
VAR_TEMP
    xEdge : BOOL;
END_VAR
