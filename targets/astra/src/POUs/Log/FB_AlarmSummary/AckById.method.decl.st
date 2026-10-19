// Квитировать тревогу по номеру (таблица HMI, stStationCmd.udiAckId). TRUE — тревога найдена и была
// неквитирована (запрос выполнит ближайший вызов её источника); FALSE — нет такой или квитировать нечего
METHOD AckById : BOOL
VAR_INPUT
    udiId : UDINT;
END_VAR
VAR
    itfAlm : PL.I_Alarm;
END_VAR
