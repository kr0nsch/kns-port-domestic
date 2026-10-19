itfTimeAct := itfTime;
IF itfTimeAct = 0 THEN
    itfTimeAct := fbSysTime;
END_IF
// часы реального времени: ошибка или время раньше LOG_UTC_MIN_MS (часы не выставлены) — метка 0
uliUtc_ms := F_UtcNowMs();
xClockValid := uliUtc_ms <> 0;
udiSeqLast := udiSeqLast + 1;
astRing[uiHead].udiSeq := udiSeqLast;
astRing[uiHead].eKind := eKind;
astRing[uiHead].ePriority := ePriority;
astRing[uiHead].udiId := udiId;
astRing[uiHead].eOldState := eOldState;
astRing[uiHead].eNewState := eNewState;
astRing[uiHead].eReason := eReason;
astRing[uiHead].wReserve := 0;
astRing[uiHead].rValue := rValue;
astRing[uiHead].uliUtc_ms := uliUtc_ms;
astRing[uiHead].lrMono_s := PL.F_LTimeToSec(ltIn := itfTimeAct.Now());
uiHead := (uiHead + 1) MOD GVL_Const.LOG_CAPACITY;
IF uiCount < GVL_Const.LOG_CAPACITY THEN
    uiCount := uiCount + 1;
ELSE
    udiOverwritten := udiOverwritten + 1;
END_IF
Store := TRUE;
