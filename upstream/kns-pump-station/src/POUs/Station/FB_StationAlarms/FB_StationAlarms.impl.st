wAlmActive := 0;
wAlmUnack := 0;
wAlmShelved := 0;
ePrioUnack := PL.E_AlarmPriority.None;
FOR uiSlot := 1 TO GVL_Const.STN_ALARM_COUNT DO
    wBit := SHL(WORD#1, uiSlot - 1);
    // Запросы команд — до вызова тела: его выполняет вызов в этом же цикле (R3 контракта).
    // Shelve(T#0S) — на tShelveMax тревоги; при tShelveMax = 0 (EHL) FB_Alarm отклоняет запрос
    IF xAckAll OR (wAckReq AND wBit) <> 0 THEN
        afbAlarm[uiSlot].Ack();
    END_IF
    IF (wShelveReq AND wBit) <> 0 THEN
        afbAlarm[uiSlot].Shelve(tDuration := T#0S);
    END_IF
    IF (wUnshelveReq AND wBit) <> 0 THEN
        afbAlarm[uiSlot].Unshelve();
    END_IF
    // условие при подавлении не копит выдержку: после снятия подавления она отсчитывается заново. Иначе условие,
    // которое держится ещё цикл (станция видит выходы устройств циклом позже: после «сухого хода» и восстановления
    // питания насосы ещё «недоступны»), давало мелькание KNS1.NORES (High, сирена) — прогон ПМИ 19.10.2026
    afbAlarm[uiSlot](xIn := axCond[uiSlot] AND NOT axSuppress[uiSlot], xSuppress := axSuppress[uiSlot],
                     xOutOfService := FALSE,
                     udiId := GVL_Const.STN_ALARM_ID_BASE + UINT_TO_UDINT(uiSlot), rValue := arValue[uiSlot],
                     stCfg := stCfg.astAlarm[uiSlot], itfTime := itfTime);
    eState := afbAlarm[uiSlot].eState;
    IF afbAlarm[uiSlot].xActive THEN
        wAlmActive := wAlmActive OR wBit;
    END_IF
    IF afbAlarm[uiSlot].xUnacked THEN
        wAlmUnack := wAlmUnack OR wBit;
        IF TO_INT(afbAlarm[uiSlot].AlarmPriority) > TO_INT(ePrioUnack) THEN
            ePrioUnack := afbAlarm[uiSlot].AlarmPriority;
        END_IF
    END_IF
    // дополнение к активным: отложены оператором, подавлены логикой, выведены из работы
    IF eState = PL.E_AlarmState.Shelved OR eState = PL.E_AlarmState.SuppressedByDesign
       OR eState = PL.E_AlarmState.OutOfService THEN
        wAlmShelved := wAlmShelved OR wBit;
    END_IF
END_FOR
