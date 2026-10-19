// 6.1 Цель: Auto — по запросу автоматики, Manual — по команде оператора, Local/OOS — нет;
//     блокировка (Auto/Manual) — положение безопасности (Stay — стоп)
IF eMode = E_DeviceMode.Auto THEN
    IF xAutoOpen THEN
        eTarget := E_ValveState.Open;
    ELSE
        eTarget := E_ValveState.Closed;
    END_IF
ELSIF eMode = E_DeviceMode.Manual THEN
    eTarget := eManTarget;
ELSE
    eTarget := E_ValveState.Intermediate;
END_IF
IF xIlkAct THEN
    IF stCfgLkg.eSafePos = E_ValveSafePos.Open THEN
        eTarget := E_ValveState.Open;
    ELSIF stCfgLkg.eSafePos = E_ValveSafePos.Closed THEN
        eTarget := E_ValveState.Closed;
    ELSE
        eTarget := E_ValveState.Intermediate;
    END_IF
    // блокировка не фиксируется: после её снятия Manual остаётся в положении безопасности
    IF eMode = E_DeviceMode.Manual THEN
        eManTarget := eTarget;
    END_IF
END_IF

// 6.2 Первопричина: при переходе слова блокировок из 0 в не 0 — номер младшего взведённого бита
//     (держится до Reset или входа в OutOfService). Цикл конечен: wIlk <> 0
IF wIlkPrev = 0 AND wIlk <> 0 AND eMode <> E_DeviceMode.OutOfService THEN
    wBit := 1;
    uiBit := 0;
    WHILE (wIlk AND wBit) = 0 DO
        wBit := SHL(wBit, 1);
        uiBit := uiBit + 1;
    END_WHILE
    uiFirstOut := uiBit;
END_IF
wIlkPrev := wIlk;
