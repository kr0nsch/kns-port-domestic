stEvent.udiId := udiId;
stEvent.ePriority := ePrioAct;
stEvent.eOldState := eState;
stEvent.eNewState := eNew;
stEvent.eReason := eReason;
stEvent.ltTime := ltNow;
stEvent.rValue := SEL(F_IsFinite(rIn := rValue), 0.0, rValue);

eState := eNew;
udiSeq := udiSeq + 1;
ltLastChange := ltNow;

IF GVL_Lib.itfAlarmSink <> 0 THEN
    GVL_Lib.itfAlarmSink.OnAlarmEvent(stEvent := stEvent);
END_IF
