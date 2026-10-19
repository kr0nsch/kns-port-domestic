// Отложить (xShelve) тревогу по номеру на её tShelveMax или вернуть отложенную. TRUE — тревога найдена и
// запрос принят (Shelve: приоритет не None, tShelveMax > 0, не OutOfService; Unshelve: была отложена)
METHOD ShelveById : BOOL
VAR_INPUT
    udiId   : UDINT;
    xShelve : BOOL;                 // TRUE — отложить, FALSE — вернуть
END_VAR
VAR
    itfAlm : PL.I_Alarm;
END_VAR
