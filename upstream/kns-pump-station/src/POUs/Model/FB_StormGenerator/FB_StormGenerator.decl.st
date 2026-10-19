// Назначение: ливни модели по seed. На сутки d — начальное состояние x0 = udiSeed XOR (d · 16#9E3779B9),
//             равномерные u = (x AND 16#00FFFFFF) / 2^24 по шагам F_Xorshift32: число ливней
//             0…uiStormsPerDayMax, для каждого — начало (равномерно в сутках), длительность (между
//             tDurationMin и tDurationMax), пик (между rPeakMin_m3h и rPeakMax_m3h). Форма — трапеция:
//             рост 15 %, полка 50 %, спад 35 % длительности. Ливни зависят только от seed и номера
//             суток — одинаковы при любом ускорении и шаге вызова. Ливень предыдущих суток, который
//             не закончился к полуночи, продолжается. StartNow — внеочередной ливень той же формы,
//             Clear — снять идущие ливни (xResetPlant).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 11.2
FUNCTION_BLOCK FB_StormGenerator
VAR_INPUT
    lrClock_h         : LREAL;      // часы модели: ч от полуночи суток 0
    udiSeed           : UDINT;      // stSimCfg.udiSeed
    uiStormsPerDayMax : UINT;       // не больше SIM_STORMS_MAX (больше — ограничивается)
    rPeakMin_m3h      : REAL;
    rPeakMax_m3h      : REAL;
    tDurationMin      : TIME;
    tDurationMax      : TIME;
END_VAR
VAR_OUTPUT
    rInflow_m3h : REAL;             // приток ливней сейчас
    xActive     : BOOL;             // идёт хотя бы один ливень
    udiDay      : UDINT;            // номер суток модели
    uiCount     : UINT;             // ливней в текущих сутках
    astStorm    : ARRAY[1..GVL_Const.SIM_STORMS_MAX] OF ST_StormEvent;   // ливни текущих суток, 1…uiCount
END_VAR
VAR
    astPrev     : ARRAY[1..GVL_Const.SIM_STORMS_MAX] OF ST_StormEvent;   // ливни предыдущих суток
    uiPrevCount : UINT;
    astWork     : ARRAY[1..GVL_Const.SIM_STORMS_MAX] OF ST_StormEvent;   // результат Generate
    dwState     : DWORD;            // состояние генератора при заполнении суток
    xGenerated  : BOOL;             // ливни заполнены для udiDayGen и параметров ниже
    udiDayGen   : UDINT;
    udiSeedGen  : UDINT;
    uiMaxGen    : UINT;
    rPeakMinGen : REAL;
    rPeakMaxGen : REAL;
    tMinGen     : TIME;
    tMaxGen     : TIME;
    xManual     : BOOL;             // внеочередной ливень (StartNow) ещё не закончился
    stManual    : ST_StormEvent;    // его длительность и пик
    lrManualStart_h : LREAL;        // его начало по часам модели
    lrSuppress_h : LREAL := -1.0;   // ливни, начавшиеся раньше этого момента, сняты (Clear)
    uiStorm     : UINT;             // индекс ливня
    lrStart_h   : LREAL;            // начало ливня по часам модели
END_VAR
