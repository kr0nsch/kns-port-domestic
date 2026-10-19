// Внеочередной ливень (stSimCmd.xStormNow): трапеция с пиком rPeak_m3h и длительностью tDuration
// от момента lrStartAt_h; заменяет предыдущий внеочередной ливень. Длительность 0 или пик ≤ 0 — не начинается
METHOD PUBLIC StartNow
VAR_INPUT
    lrStartAt_h : LREAL;    // начало по часам модели (обычно текущие часы)
    rPeak_m3h   : REAL;     // пик притока
    tDuration   : TIME;     // длительность
END_VAR
