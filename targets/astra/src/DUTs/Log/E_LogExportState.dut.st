// Назначение: состояние выгрузки журнала в CSV (GVL_Log.eExportState, stStationSts.eLogExport).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.2
{attribute 'qualified_only'}
// PORT: [pragma] проверить в Astra.IDE — {attribute 'strict'} у перечисления (C5)
{attribute 'strict'}
TYPE E_LogExportState :
(
    Idle     := 0,   // выгрузки не было
    Snapshot := 1,   // снимок кольца сделан, ждёт SlowTask
    Writing  := 2,   // SlowTask пишет файл
    Done     := 3,   // файл записан
    Error    := 4    // ошибка CAA File
// PORT: [types] проверить в Astra.IDE — перечисление с базовым типом INT (C7)
) INT;
END_TYPE
