// Назначение: текущее время UTC, мс от 1970 (SysTimeRtcHighResGet) для меток журнала и списка тревог;
//             0 — часы недоступны или не выставлены (время раньше LOG_UTC_MIN_MS).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 9.1, 9.3
FUNCTION F_UtcNowMs : ULINT
VAR
    uliNow_ms : ULINT;              // ответ часов реального времени
END_VAR
