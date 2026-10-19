// запрос принимается, только пока выгрузка не идёт (фронт xExecute FB_EventLogCsv — по принятию)
xStart := GVL_Log.xExportReq AND fbCsv.eState <> E_LogExportState.Writing;
fbCsv(xExecute := xStart, sFileName := GVL_Const.LOG_CSV_FILE, fbLog := GVL_Log.fbEventLog);
// итог — до состояния: MainTask по переходу в Done/Error пишет событие с числом строк или кодом ошибки
IF fbCsv.xDone OR fbCsv.xError THEN
    GVL_Log.uiExportLines := fbCsv.uiLines;
    GVL_Log.udiExportError := fbCsv.udiError;
END_IF
GVL_Log.eExportState := fbCsv.eState;
// запрос снимается после публикации Writing: при Writing MainTask новый запрос не ставит
IF xStart THEN
    GVL_Log.xExportReq := FALSE;
END_IF
