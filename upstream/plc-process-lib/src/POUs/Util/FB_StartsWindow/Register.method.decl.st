// Добавить отметку пуска; при заполнении кольца затирается самая старая
METHOD PUBLIC Register
VAR_INPUT
    ltNow : LTIME;   // время пуска
END_VAR
VAR
    xMore : BOOL;    // продолжать удаление с конца
    uiLast : UINT;   // индекс самой новой отметки
END_VAR
