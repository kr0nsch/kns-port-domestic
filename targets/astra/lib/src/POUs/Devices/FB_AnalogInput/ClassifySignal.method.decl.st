// Шаг 6.1 цикла: мгновенная классификация сигнала (до подтверждения tFailDelay). NE 43 — только для
// MilliAmp и Norm420 (I = 4 + 16·rIn); старшинство NotFinite > ChannelFault > FailLow/FailHigh >
// UnderRange/OverRange > Good. Границы 3,6 и 21,0 мА включены в отказ (A-02, сверить с NAMUR NE 43).
// Читает входы rIn, xChannelFault и stCfgLkg; ничего не меняет
METHOD PROTECTED ClassifySignal : E_AiSignalState
VAR
    rI_mA : REAL;   // ток для проверки NE 43, мА
END_VAR
