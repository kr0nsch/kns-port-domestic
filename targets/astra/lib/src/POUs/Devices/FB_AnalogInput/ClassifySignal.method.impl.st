IF NOT F_IsFinite(rIn := rIn) THEN
    ClassifySignal := E_AiSignalState.NotFinite;
ELSIF xChannelFault THEN
    ClassifySignal := E_AiSignalState.ChannelFault;
ELSIF stCfgLkg.eInput = E_AiInputType.MilliAmp OR stCfgLkg.eInput = E_AiInputType.Norm420 THEN
    IF stCfgLkg.eInput = E_AiInputType.Norm420 THEN
        rI_mA := GVL_Const.MA_ZERO + GVL_Const.MA_SPAN * rIn;
    ELSE
        rI_mA := rIn;
    END_IF
    IF rI_mA <= GVL_Const.NE43_FAIL_LOW_MA THEN
        ClassifySignal := E_AiSignalState.FailLow;
    ELSIF rI_mA >= GVL_Const.NE43_FAIL_HIGH_MA THEN
        ClassifySignal := E_AiSignalState.FailHigh;
    ELSIF rI_mA < GVL_Const.NE43_MEAS_LOW_MA THEN
        ClassifySignal := E_AiSignalState.UnderRange;
    ELSIF rI_mA > GVL_Const.NE43_MEAS_HIGH_MA THEN
        ClassifySignal := E_AiSignalState.OverRange;
    ELSE
        ClassifySignal := E_AiSignalState.Good;
    END_IF
ELSE
    // Norm01, Eng, Raw: NE 43 не применяется
    ClassifySignal := E_AiSignalState.Good;
END_IF
