// Назначение: задержка включения и отключения дискретного сигнала — единственный таймер
//             библиотеки (TON, TOF, TP в коде библиотеки не используются). Время берётся из
//             I_TimeSource один раз за вызов; itfTime = 0 — встроенный FB_SystemTime.
//             «Время назад» (ltNow < отметки) перезапускает отсчёт, выход не меняется.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Delay.md
FUNCTION_BLOCK FB_Delay
VAR_INPUT
    xIn       : BOOL;               // входной сигнал
    tOnDelay  : TIME := T#0S;       // задержка фронта (включения)
    tOffDelay : TIME := T#0S;       // задержка спада (отключения)
    itfTime   : I_TimeSource;       // источник времени; 0 — встроенный fbSysTime
END_VAR
VAR_OUTPUT
    xOut       : BOOL;              // сигнал после задержек
    xTimingOn  : BOOL;              // xIn = TRUE, xOut = FALSE: идёт отсчёт задержки включения
    xTimingOff : BOOL;              // xIn = FALSE, xOut = TRUE: идёт отсчёт задержки отключения
    tRemaining : TIME;              // до смены xOut; T#0S — отсчёта нет
END_VAR
VAR
    fbSysTime : FB_SystemTime;      // запасной источник времени
    ltChange  : LTIME;              // отметка начала отсчёта: смена xIn, первый вызов, Preset, «время назад»
    xInPrev   : BOOL;               // xIn предыдущего вызова
    xRestart  : BOOL := TRUE;       // поставить отметку в ближайшем вызове (первый вызов, Preset)
END_VAR
VAR_TEMP
    ltNow     : LTIME;              // время этого вызова
    ltDelay   : LTIME;              // действующая задержка для текущего xIn
    ltElapsed : LTIME;              // прошло с отметки
END_VAR
