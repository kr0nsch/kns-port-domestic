// 1. Время этого вызова — один раз
IF itfTime <> 0 THEN
    ltNow := itfTime.Now();
ELSE
    ltNow := fbSysTime.Now();
END_IF

// 2. Отметка начала отсчёта. Проверка «время назад» — первой: LTIME без знака, и разность
//    ltNow - ltChange при ltNow < ltChange переполнилась бы. Отметка ставится и при смене xIn,
//    в первом вызове и после Preset. После этого шага ltNow >= ltChange.
ltChange := SEL(ltNow < ltChange OR xRestart OR (xIn <> xInPrev), ltChange, ltNow);
xRestart := FALSE;
xInPrev := xIn;

// 3. Задержка для текущего xIn; изменение уставки во время отсчёта действует сразу
ltDelay := TIME_TO_LTIME(SEL(xIn, tOffDelay, tOnDelay));
ltElapsed := ltNow - ltChange;

// 4. Смена выхода, когда задержка истекла; T#0S — в том же вызове. Если xIn вернулся раньше,
//    xIn = xOut и присваивание ничего не меняет: ожидание отменено
xOut := SEL(ltElapsed >= ltDelay, xOut, xIn);

// 5. Диагностика отсчёта
xTimingOn := xIn AND NOT xOut;
xTimingOff := xOut AND NOT xIn;
IF xIn <> xOut THEN
    // выход не сменился, значит ltElapsed < ltDelay: разность без переполнения
    tRemaining := LTIME_TO_TIME(ltDelay - ltElapsed);
ELSE
    tRemaining := T#0S;
END_IF
