// Насос: пример для метрик переноса
FUNCTION_BLOCK FB_Pump EXTENDS FB_Base
VAR_INPUT
    xStart : BOOL;
    stCfg : ST_PumpCfg;
END_VAR
VAR_OUTPUT
    xRunning : BOOL;
END_VAR
VAR
    tonDelay : TON;
END_VAR
