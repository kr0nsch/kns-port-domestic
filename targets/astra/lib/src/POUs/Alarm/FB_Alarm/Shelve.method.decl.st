// Запрос shelve; выполняет ближайший вызов тела. TRUE — принято: приоритет не None,
// tShelveMax > 0 и тревога не в OutOfService
METHOD PUBLIC Shelve : BOOL
VAR_INPUT
    tDuration : TIME;   // срок; T#0S — tShelveMax, больше tShelveMax — обрезается
END_VAR
