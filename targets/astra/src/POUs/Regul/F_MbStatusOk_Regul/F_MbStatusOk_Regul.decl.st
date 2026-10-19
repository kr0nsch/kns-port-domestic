// Назначение: признак «обмен исправен» по статусу канала драйвера Modbus REGUL (перечисление ChannelStatus,
//             значения 0…6). Исправны только значения, отмеченные в GVL_ConstRegul.MB_STATUS_OK; значение вне
//             диапазона — потеря связи (индекс массива не выходит за границы).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   targets/astra/README.md; docs/migration_checklist.md, раздел 4
// PORT: [comm] новый объект: статус канала Modbus REGUL вместо диагностики слейвов CODESYS [F58]
FUNCTION F_MbStatusOk_Regul : BOOL
VAR_INPUT
    iStatus : INT;      // статус канала, приведённый к INT
END_VAR
