// Число отметок t с t <= ltNow и ltNow - t < STARTS_WINDOW. Отметки «из будущего» (время
// назад) и старше окна удаляются
METHOD PUBLIC Count : UINT
VAR_INPUT
    ltNow : LTIME;    // текущее время
END_VAR
VAR
    xMore : BOOL;     // продолжать удаление
    uiLast : UINT;    // индекс самой новой отметки
    uiFirst : UINT;   // индекс самой старой отметки
END_VAR
