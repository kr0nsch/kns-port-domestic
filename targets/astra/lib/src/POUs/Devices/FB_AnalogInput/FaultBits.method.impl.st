IF xFail AND eSignal = E_AiSignalState.FailLow THEN
    FaultBits := GVL_Const.AI_FLT_FAIL_LOW;
ELSIF xFail AND eSignal = E_AiSignalState.FailHigh THEN
    FaultBits := GVL_Const.AI_FLT_FAIL_HIGH;
ELSIF xFail AND eSignal = E_AiSignalState.ChannelFault THEN
    FaultBits := GVL_Const.AI_FLT_CHANNEL;
ELSIF xFail AND eSignal = E_AiSignalState.NotFinite THEN
    FaultBits := GVL_Const.AI_FLT_NOT_FINITE;
ELSE
    // отказа нет или сигнал уже вернулся (идёт подтверждение возврата)
    FaultBits := 0;
END_IF
