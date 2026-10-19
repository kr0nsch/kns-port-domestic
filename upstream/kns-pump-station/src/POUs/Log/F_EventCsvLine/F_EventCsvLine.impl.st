IF stRecord.eKind = E_EventKind.Alarm THEN
    sKind := 'alarm';
ELSE
    sKind := 'station';
END_IF
// seq;time_utc;kind;id;code;
sHead := CONCAT(CONCAT(UDINT_TO_STRING(stRecord.udiSeq), SEP),
                CONCAT(F_UtcToIso(uliUtc_ms := stRecord.uliUtc_ms), SEP));
sHead := CONCAT(sHead, CONCAT(CONCAT(sKind, SEP), CONCAT(UDINT_TO_STRING(stRecord.udiId), SEP)));
sHead := CONCAT(sHead, CONCAT(F_AlarmCode(udiId := stRecord.udiId), SEP));
// priority;old_state;new_state;reason;value
sTail := CONCAT(CONCAT(INT_TO_STRING(TO_INT(stRecord.ePriority)), SEP),
                CONCAT(INT_TO_STRING(TO_INT(stRecord.eOldState)), SEP));
sTail := CONCAT(sTail, CONCAT(CONCAT(INT_TO_STRING(TO_INT(stRecord.eNewState)), SEP),
                              CONCAT(INT_TO_STRING(TO_INT(stRecord.eReason)), SEP)));
F_EventCsvLine := CONCAT(CONCAT(sHead, sTail), CONCAT(REAL_TO_STRING(stRecord.rValue), CRLF));
