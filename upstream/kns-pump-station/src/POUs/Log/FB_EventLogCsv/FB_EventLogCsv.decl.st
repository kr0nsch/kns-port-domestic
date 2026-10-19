// Назначение: выгрузка снимка журнала в CSV через CAA File (SlowTask, PRG_Slow): по фронту xExecute —
//             FILE.Open (MWRITE) → заголовок и строки снимка FB_EventLog по LOG_CSV_LINES_PER_WRITE за один
//             FILE.Write → FILE.Close. Файл — ASCII, «;», CRLF (F_EventCsvLine). Состояние: Writing, затем
//             Done (uiLines строк) или Error (udiError — код FILE.ERROR); держится до следующего фронта.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 9.2; docs/ARCHITECTURE.md, раздел 7
FUNCTION_BLOCK FB_EventLogCsv
VAR_INPUT
    xExecute  : BOOL;               // фронт — начать выгрузку (PRG_Slow: GVL_Log.xExportReq)
    sFileName : STRING(GVL_Const.LOG_PATH_LEN) := GVL_Const.LOG_CSV_FILE;   // относительный путь — каталог рантайма
END_VAR
VAR_IN_OUT
    fbLog : FB_EventLog;            // журнал со снимком (GVL_Log.fbEventLog; TakeSnapshot — MainTask)
END_VAR
VAR_OUTPUT
    eState   : E_LogExportState;    // Idle, Writing, Done, Error
    uiLines  : UINT;                // записано строк данных (без заголовка)
    udiError : UDINT;               // код FILE.ERROR операции с ошибкой; 0 — нет
    xDone    : BOOL;                // файл записан и закрыт
    xError   : BOOL;                // ошибка открытия, записи или закрытия
END_VAR
VAR
    fbOpen    : FILE.Open;
    fbWrite   : FILE.Write;
    fbClose   : FILE.Close;
    xExecPrev : BOOL;               // xExecute прошлого вызова (фронт)
    iStep     : INT;                // шаг выгрузки (STEP_*)
    uiNext    : UINT;               // индекс следующей записи снимка
    xFailed   : BOOL;               // была ошибка записи: после закрытия — Error
    abBuf     : ARRAY[0..GVL_Const.LOG_CSV_BUF_LEN - 1] OF BYTE;   // строки одной операции FILE.Write
    udiBufLen : UDINT;              // байт в abBuf
    stRec     : ST_EventRecord;     // запись снимка
    uiI       : UINT;               // строка порции
END_VAR
VAR CONSTANT
    STEP_IDLE  : INT := 0;
    STEP_OPEN  : INT := 1;
    STEP_WRITE : INT := 2;
    STEP_CLOSE : INT := 3;
    STEP_END   : INT := 4;
    MODE_WRITE : FILE.MODE := FILE.MODE.MWRITE;   // новый файл (существующий перезаписывается)
END_VAR
