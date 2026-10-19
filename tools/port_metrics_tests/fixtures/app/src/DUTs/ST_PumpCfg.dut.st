TYPE ST_PumpCfg :
STRUCT
    rSpeedMax_Hz : REAL := 50.0; // предел частоты
    tStartDelay : TIME := T#5S;
END_STRUCT
END_TYPE
