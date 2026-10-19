// 1. Противоречия поплавков и уровнемера (таблица 04 §10.5) — только при достоверном LT101;
//    подтверждение tLdev
fbLs102False(xIn := xLevelValid AND xFloatHigh AND rLevel_m < stCfg.rLdev102On_m,
             tOnDelay := stCfg.tLdev, itfTime := itfTime);
fbLs102Missed(xIn := xLevelValid AND NOT xFloatHigh AND rLevel_m > stCfg.rLdev102Off_m,
              tOnDelay := stCfg.tLdev, itfTime := itfTime);
fbLs103False(xIn := xLevelValid AND xFloatDry AND rLevel_m > stCfg.rLdev103On_m,
             tOnDelay := stCfg.tLdev, itfTime := itfTime);
fbLs103Missed(xIn := xLevelValid AND NOT xFloatDry AND rLevel_m < stCfg.rLdev103Off_m,
              tOnDelay := stCfg.tLdev, itfTime := itfTime);
xContrRaw := fbLs102False.xTimingOn OR fbLs102False.xOut OR fbLs102Missed.xTimingOn OR fbLs102Missed.xOut
             OR fbLs103False.xTimingOn OR fbLs103False.xOut OR fbLs103Missed.xTimingOn OR fbLs103Missed.xOut;

// 2. Кому доверять — по статусу уровнемера (NE 43, 04 §10.5). Вне диапазона (OutOfSpecification) и
//    противоречит любому поплавку дольше tLdev — уровнемер исключается: «уплывший» к краю шкалы
//    датчик не держит насосы заблокированными. Маска уровнемера снимается, когда сигнал вернулся в
//    норму (Good) и противоречия нет дольше tLtRecover
IF xLevelValid AND eLevelNe107 = PL.E_Ne107Status.OutOfSpecification
   AND (fbLs102False.xOut OR fbLs102Missed.xOut OR fbLs103False.xOut OR fbLs103Missed.xOut) THEN
    xLtMasked := TRUE;
END_IF
fbLtRecover(xIn := xLtMasked AND xLevelValid AND eLevelNe107 = PL.E_Ne107Status.Good AND NOT xContrRaw,
            tOnDelay := stCfg.tLtRecover, itfTime := itfTime);
IF fbLtRecover.xOut THEN
    xLtMasked := FALSE;
END_IF
xLevelUsable := xLevelValid AND NOT xLtMasked;

// 3. Маски поплавков: уровнемер годен и не вне спецификации — виноват поплавок, сработавший ложно.
//    Маска снимается сама, когда поплавок вернулся, и сразу, когда уровнемер негоден: без него
//    поплавки — единственный источник (события 101011/101012, значение 102 или 103)
xGood := xLevelUsable AND eLevelNe107 <> PL.E_Ne107Status.OutOfSpecification;
xMaskPrev := xLs102Masked;
IF fbLs102False.xOut AND xGood THEN
    xLs102Masked := TRUE;
END_IF
IF NOT xFloatHigh OR NOT xLevelUsable THEN
    xLs102Masked := FALSE;
END_IF
IF xLs102Masked <> xMaskPrev AND itfEvents <> 0 THEN
    IF xLs102Masked THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.FloatMasked, rValue := GVL_Const.STN_EVT_LS102);
    ELSE
        itfEvents.LogEvent(eEvent := E_StationEvent.FloatUnmasked, rValue := GVL_Const.STN_EVT_LS102);
    END_IF
END_IF
xMaskPrev := xLs103Masked;
IF fbLs103False.xOut AND xGood THEN
    xLs103Masked := TRUE;
END_IF
IF NOT xFloatDry OR NOT xLevelUsable THEN
    xLs103Masked := FALSE;
END_IF
IF xLs103Masked <> xMaskPrev AND itfEvents <> 0 THEN
    IF xLs103Masked THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.FloatMasked, rValue := GVL_Const.STN_EVT_LS103);
    ELSE
        itfEvents.LogEvent(eEvent := E_StationEvent.FloatUnmasked, rValue := GVL_Const.STN_EVT_LS103);
    END_IF
END_IF

// 4. Противоречия для KNS1.LDEV и HMI
wLdev := 0;
IF fbLs102False.xOut THEN
    wLdev := wLdev OR GVL_Const.STN_LDEV_LS102_FALSE;
END_IF
IF fbLs102Missed.xOut THEN
    wLdev := wLdev OR GVL_Const.STN_LDEV_LS102_MISSED;
END_IF
IF fbLs103False.xOut THEN
    wLdev := wLdev OR GVL_Const.STN_LDEV_LS103_FALSE;
END_IF
IF fbLs103Missed.xOut THEN
    wLdev := wLdev OR GVL_Const.STN_LDEV_LS103_MISSED;
END_IF
IF xLtMasked THEN
    wLdev := wLdev OR GVL_Const.STN_LDEV_LT_MASKED;
END_IF
xLdev := wLdev <> 0;

// 5. Сухой ход станции (04 §10.1). Снятие без уровнемера — LS103 снят дольше tDryRelease, пока
//    действует защита при негодном уровнемере (отсчёт с момента, когда опираться можно только на
//    поплавок)
xDryFloat := xFloatDry AND NOT xLs103Masked;
xDryLt := xLevelUsable AND xLevelLL;
fbDryRelease(xIn := xDryRun AND NOT xLevelUsable AND NOT xDryFloat, tOnDelay := stCfg.tDryRelease,
             itfTime := itfTime);
IF xDryFloat OR xDryLt THEN
    xDryRun := TRUE;
ELSIF xDryRun THEN
    IF (xLevelUsable AND NOT xLevelL) OR (NOT xLevelUsable AND fbDryRelease.xOut) THEN
        xDryRun := FALSE;
    END_IF
END_IF

// 6. Аварийно высокий уровень (04 §10.2): взвод LS102 или HH, снятие — LS102 снят и ниже H (или
//    уровнемер негоден: тогда LS102 обрабатывает режим по поплавкам)
xEhlFloat := xFloatHigh AND NOT xLs102Masked;
xEhlLt := xLevelUsable AND xLevelHH;
IF xEhlFloat OR xEhlLt THEN
    xEmergency := TRUE;
ELSIF xEmergency THEN
    IF NOT xLevelUsable OR NOT xLevelH THEN
        xEmergency := FALSE;
    END_IF
END_IF

// 7. Режим по поплавкам (04 §11): вход сразу при негодном уровнемере (работающие насосы — сразу
//    «откачка»), выход — уровень годен tLtRecover. Откачка — от LS102 до LS103
fbFloatExit(xIn := xLevelUsable, tOnDelay := stCfg.tLtRecover, itfTime := itfTime);
IF NOT xLevelUsable AND NOT xFirstCall THEN
    IF NOT xFloatMode THEN
        xFloatMode := TRUE;
        xFloatPumping := uiRunning > 0;
        IF itfEvents <> 0 THEN
            itfEvents.LogEvent(eEvent := E_StationEvent.FloatModeOn, rValue := 0.0);
        END_IF
    END_IF
ELSIF xFloatMode AND fbFloatExit.xOut THEN
    xFloatMode := FALSE;
    xFloatPumping := FALSE;
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.FloatModeOff, rValue := 0.0);
    END_IF
END_IF
IF xFloatMode THEN
    IF xFloatDry THEN
        xFloatPumping := FALSE;                         // LS103: все насосы стоп (сухой ход старше)
    ELSIF xFloatHigh THEN
        xFloatPumping := TRUE;                          // LS102: все доступные насосы, 100 %
    END_IF
END_IF
uiFloatRequired := SEL(xFloatMode AND xFloatPumping, 0, GVL_Const.STN_PUMP_COUNT);
xFirstCall := FALSE;
