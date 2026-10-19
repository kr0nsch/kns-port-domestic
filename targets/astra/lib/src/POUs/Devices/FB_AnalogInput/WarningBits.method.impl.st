IF xOor AND eSignal = E_AiSignalState.UnderRange THEN
    wBits := GVL_Const.AI_WRN_UNDER_RANGE;
ELSIF xOor AND eSignal = E_AiSignalState.OverRange THEN
    wBits := GVL_Const.AI_WRN_OVER_RANGE;
END_IF
IF xClamped THEN
    wBits := wBits OR GVL_Const.AI_WRN_CLAMPED;
END_IF
WarningBits := wBits;
