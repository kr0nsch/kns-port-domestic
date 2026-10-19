// Через сколько число пусков в окне станет меньше uiMax; LTIME#0S, если uiMax = 0 (без
// ограничения) или пусков уже меньше uiMax
METHOD PUBLIC TimeToFree : LTIME
VAR_INPUT
    ltNow : LTIME;    // текущее время
    uiMax : UINT;     // лимит пусков в окне
END_VAR
VAR
    uiCount : UINT;   // пусков в окне
    uiIdx : UINT;     // индекс отметки, после истечения которой пусков станет uiMax - 1
END_VAR
