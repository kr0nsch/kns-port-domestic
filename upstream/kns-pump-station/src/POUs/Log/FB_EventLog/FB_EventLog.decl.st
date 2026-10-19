// Назначение: журнал событий КНС-1 — кольцевой буфер LOG_CAPACITY (200) записей ST_EventRecord в ОЗУ:
//             переходы тревог устройств, станции и LIC101 (приёмник PL.I_AlarmSink, ссылка в
//             PL.GVL_Lib.itfAlarmSink) и события станции (I_StationEventSink, номер STN_EVENT_ID_BASE + код).
//             При переполнении затирается самая старая запись (udiOverwritten). Метки: UTC от
//             SysTimeRtcHighResGet (мс; 0 — часы недоступны) и время процесса lrMono_s по itfTime.
//             Страница HMI (FillView), курсор внешних клиентов (FillFeed), снимок для CSV (TakeSnapshot —
//             MainTask, GetSnapshotRecord — SlowTask). Тело пустое: записи делают методы в момент события.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 9.1; docs/04_algorithms.md, раздел 16
FUNCTION_BLOCK FB_EventLog IMPLEMENTS PL.I_AlarmSink, I_StationEventSink
VAR_INPUT
    itfTime : PL.I_TimeSource;      // GVL_Time.fbClockMain (присваивает PRG_Station каждый цикл); 0 — LTIME()
END_VAR
VAR_OUTPUT
    uiCount        : UINT;          // записей в кольце, 0…LOG_CAPACITY
    udiSeqLast     : UDINT;         // номер последней записи; 0 — записей не было
    udiOverwritten : UDINT;         // затёрто записей с запуска
    xClockValid    : BOOL;          // последняя запись: RTC ответил и время правдоподобно
END_VAR
VAR
    astRing     : ARRAY[0..GVL_Const.LOG_CAPACITY - 1] OF ST_EventRecord;   // кольцо
    uiHead      : UINT;             // индекс следующей записи в кольце
    astSnapshot : ARRAY[0..GVL_Const.LOG_CAPACITY - 1] OF ST_EventRecord;   // снимок, от старой записи к новой
    uiSnapCount : UINT;             // записей в снимке
    fbSysTime   : PL.FB_SystemTime; // источник времени без itfTime
END_VAR
