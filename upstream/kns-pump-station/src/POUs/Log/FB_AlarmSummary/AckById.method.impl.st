itfAlm := FindAlarm(udiId := udiId);
IF itfAlm <> 0 THEN
    AckById := itfAlm.Ack();
ELSE
    AckById := FALSE;
END_IF
