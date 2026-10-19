// Запись по возрасту: 0 — самая новая; FALSE — такой записи нет (stRecord — нули, udiSeq = 0)
METHOD GetRecord : BOOL
VAR_INPUT
    uiAge : UINT;                   // 0 — новая, uiCount - 1 — самая старая
END_VAR
VAR_OUTPUT
    stRecord : ST_EventRecord;
END_VAR
VAR
    stEmpty : ST_EventRecord;       // пустая запись
END_VAR
