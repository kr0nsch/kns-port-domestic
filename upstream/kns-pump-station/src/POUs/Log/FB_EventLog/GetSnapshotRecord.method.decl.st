// Запись снимка (SlowTask): 0 — самая старая; FALSE — индекс вне снимка (stRecord — нули)
METHOD GetSnapshotRecord : BOOL
VAR_INPUT
    uiIndex : UINT;                 // 0…SnapshotCount - 1
END_VAR
VAR_OUTPUT
    stRecord : ST_EventRecord;
END_VAR
VAR
    stEmpty : ST_EventRecord;       // пустая запись
END_VAR
