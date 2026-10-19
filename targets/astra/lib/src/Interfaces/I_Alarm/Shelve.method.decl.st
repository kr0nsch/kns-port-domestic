// Запрос shelve. TRUE — принято: приоритет <> None, tShelveMax > 0, не OutOfService
METHOD Shelve : BOOL
VAR_INPUT
    tDuration : TIME;   // срок; T#0S — tShelveMax, больше tShelveMax — обрезается
END_VAR
