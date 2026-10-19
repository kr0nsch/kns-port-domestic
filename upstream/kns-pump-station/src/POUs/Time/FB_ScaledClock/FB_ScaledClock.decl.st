// Назначение: часы контура с ускорением имитации — источник времени PL.I_TimeSource для
//             устройств, станции, журнала (GVL_Time.fbClockMain) и модели (GVL_Time.fbClockModel).
//             Now() = база + (LTIME() − база_реальная) · k; смена k (Update в начале цикла задачи)
//             перебазирует часы, время монотонно. При k = 1 часы совпадают с LTIME(). Ручной режим
//             (SetManual, AdvanceL) — для интеграционных тестов: время меняется только шагами.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 10; docs/ARCHITECTURE.md, раздел 11
FUNCTION_BLOCK FB_ScaledClock IMPLEMENTS PL.I_TimeSource
VAR
    lrScaleAct   : LREAL := 1.0;     // действующий коэффициент k, 1…SIM_TIME_SCALE_MAX
    ltBaseScaled : LTIME;            // время контура в момент последнего перебазирования
    ltBaseReal   : LTIME;            // LTIME() в тот же момент
    xManual      : BOOL;             // ручной режим: Now() = ltManual
    ltManual     : LTIME := LTIME#1H;   // старт не с нуля (как FB_FakeTime)
    xInit        : BOOL;             // базы заданы первым вызовом Now или Update
END_VAR
