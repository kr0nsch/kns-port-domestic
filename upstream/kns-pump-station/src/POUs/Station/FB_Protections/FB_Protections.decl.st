// Назначение: защиты станции и резервное управление (04 §10.1, 10.2, 10.5, 11): сухой ход,
//             аварийно высокий уровень, согласование поплавков и уровнемера (кому доверять —
//             по NE 107 уровнемера: Good — маска поплавка, OutOfSpecification — LT101 исключается),
//             режим по поплавкам (ожидание LS102 / откачка до LS103). Во всех формулах вместо
//             fbLT101.xValid — xLevelUsable (xValid и уровнемер не исключён). Первый вызов
//             (устройства ещё не вызывались) в режим по поплавкам не переводит.
//             События 101011…101014. Демонстрация логики, не система ПАЗ (04 §10.7).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.7; docs/04_algorithms.md, разделы 10, 11
FUNCTION_BLOCK FB_Protections
VAR_INPUT
    rLevel_m    : REAL;             // fbLT101.rValue_eu
    xLevelValid : BOOL;             // fbLT101.xValid (NE 43, не OOS)
    eLevelNe107 : PL.E_Ne107Status; // fbLT101.stSts.stCommon.eNe107: OutOfSpecification — ток вне диапазона (LT101.OOR)
    xLevelL     : BOOL;             // fbLT101.xL, xLL, xH, xHH
    xLevelLL    : BOOL;
    xLevelH     : BOOL;
    xLevelHH    : BOOL;
    xFloatHigh  : BOOL;             // fbLS102.xValue (НЗ, обрыв = срабатывание)
    xFloatDry   : BOOL;             // fbLS103.xValue (eFailValue = ForceTrue)
    uiRunning   : UINT;             // работающие насосы (вход в режим по поплавкам)
    itfTime     : PL.I_TimeSource;
    itfEvents   : I_StationEventSink;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // tDryRelease, rLdev*, tLdev, tLtRecover
END_VAR
VAR_OUTPUT
    xLevelUsable    : BOOL;         // xLevelValid AND NOT xLtMasked: по нему ступенчатое, ПИД и LIC101.xPvValid
    xLtMasked       : BOOL;         // 04 §10.5: LT101 вне диапазона и противоречит поплавку дольше tLdev — исключён
    xDryRun         : BOOL;         // 04 §10.1 → KNS_ILK_DRY_RUN всем насосам; KNS1.DRY
    xEmergency      : BOOL;         // 04 §10.2 (взвод LS102 или HH; снятие ниже H)
    xFloatMode      : BOOL;         // 04 §11: NOT xLevelUsable; выход — tLtRecover годного сигнала
    uiFloatRequired : UINT;         // 0 — ожидание LS102; STN_PUMP_COUNT — откачка до LS103
    xLs102Masked    : BOOL;         // 04 §10.5
    xLs103Masked    : BOOL;
    xLdev           : BOOL;         // любое противоречие дольше tLdev (KNS1.LDEV)
    wLdev           : WORD;         // бит 0 LS102 ложно, 1 LS102 не сработал, 2 LS103 ложно, 3 LS103 не сработал,
                                    // 4 LT101 исключён (STN_LDEV_*)
END_VAR
VAR
    fbLs102False  : PL.FB_Delay;    // LS102 сработал, уровень < rLdev102On_m (tLdev)
    fbLs102Missed : PL.FB_Delay;    // LS102 не сработал, уровень > rLdev102Off_m (tLdev)
    fbLs103False  : PL.FB_Delay;    // LS103 сработал, уровень > rLdev103On_m (tLdev)
    fbLs103Missed : PL.FB_Delay;    // LS103 не сработал, уровень < rLdev103Off_m (tLdev)
    fbLtRecover   : PL.FB_Delay;    // LT101 в норме без противоречий tLtRecover → маска уровнемера снята
    fbDryRelease  : PL.FB_Delay;    // сухой ход без LT101: LS103 снят tDryRelease
    fbFloatExit   : PL.FB_Delay;    // уровень годен tLtRecover → выход из режима по поплавкам
    xFloatPumping : BOOL;           // режим по поплавкам: откачка (TRUE) или ожидание LS102
    xFirstCall    : BOOL := TRUE;   // первый вызов: выходы устройств ещё не посчитаны
END_VAR
VAR_TEMP
    xContrRaw   : BOOL;             // есть противоречие (до выдержки)
    xDryFloat   : BOOL;             // LS103 сработал и не исключён
    xDryLt      : BOOL;             // LL по годному уровнемеру
    xEhlFloat   : BOOL;             // LS102 сработал и не исключён
    xEhlLt      : BOOL;             // HH по годному уровнемеру
    xGood       : BOOL;             // уровнемер достоверен и в норме по NE 107 (виноват поплавок)
    xMaskPrev   : BOOL;             // маска поплавка до этого вызова (событие)
END_VAR
