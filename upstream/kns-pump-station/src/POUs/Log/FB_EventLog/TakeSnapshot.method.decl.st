// Снимок кольца для выгрузки CSV (MainTask): записи от старой к новой в astSnapshot. TRUE — снимок сделан.
// Вызывать, только пока SlowTask не пишет файл (GVL_Log.eExportState не Writing): снимок читает SlowTask
METHOD TakeSnapshot : BOOL
VAR
    uiI : UINT;                     // номер записи снимка, с 1
END_VAR
