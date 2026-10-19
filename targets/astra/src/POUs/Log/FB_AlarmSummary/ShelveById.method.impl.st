itfAlm := FindAlarm(udiId := udiId);
IF itfAlm = 0 THEN
    ShelveById := FALSE;
ELSIF xShelve THEN
    ShelveById := itfAlm.Shelve(tDuration := T#0S);
ELSE
    ShelveById := itfAlm.Unshelve();
END_IF
