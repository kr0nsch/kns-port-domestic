// Насос: пример для метрик переноса
// PORT: [oop] EXTENDS не подтверждён в Astra.IDE (F23) — база вложена экземпляром
FUNCTION_BLOCK FB_Pump
VAR_INPUT
    xStart : BOOL;
    stCfg : ST_PumpCfg;
END_VAR
VAR_OUTPUT
    xRunning : BOOL;
END_VAR
VAR
    tonDelay : TON;
    fbBase : FB_Base; // PORT: [oop] композиция вместо наследования
END_VAR
