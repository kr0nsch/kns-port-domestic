uiUsed := MIN(uiAlarmCount, GVL_Const.DEV_ALARMS_MAX);

// 1. Запросы: квитировать всё (xAck, xReset, AckAll(), Reset()), маски по слотам. Методы слотов
//    только ставят запрос — его выполняет вызов слота в шаге 2 этого же цикла
xAckAllNow := stCmd.xAck OR stCmd.xReset OR xAckAllReq OR xResetReq;
FOR uiLoop := 1 TO uiUsed DO
    uiSlot := uiLoop - 1;
    wBit := SHL(WORD#16#0001, uiSlot);
    IF xAckAllNow OR (stCmd.wAckReq AND wBit) <> 0 THEN
        xAccepted := afbAlarm[uiSlot].Ack();
    END_IF
    // в OutOfService shelve не принимается (10.1); проверка по режиму устройства, а не по ответу
    // слота: в вызове входа в OutOfService слот ещё не в OutOfService и ответил бы TRUE, а его тело
    // запрос отклонит — результат команды был бы ложным Accepted
    IF (stCmd.wShelveReq AND wBit) <> 0 AND eMode <> E_DeviceMode.OutOfService THEN
        xAccepted := afbAlarm[uiSlot].Shelve(tDuration := T#0S);
        xShelveAny := xShelveAny OR xAccepted;
    END_IF
    IF (stCmd.wUnshelveReq AND wBit) <> 0 THEN
        xAccepted := afbAlarm[uiSlot].Unshelve();
    END_IF
END_FOR
// результаты: «квитировать всё» (xAck и AckAll() вместе — одна команда) и каждая ненулевая маска;
// xReset и Reset() дают результат в шаге Reset устройства
IF stCmd.xAck OR xAckAllReq THEN
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF
IF stCmd.wAckReq <> 0 THEN
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF
IF stCmd.wShelveReq <> 0 THEN
    IF xShelveAny THEN
        SetCmdResult(eResult := E_CmdResult.Accepted);
    ELSE
        SetCmdResult(eResult := E_CmdResult.RejectedState);
    END_IF
END_IF
IF stCmd.wUnshelveReq <> 0 THEN
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF
stCmd.xAck := FALSE;
stCmd.xReset := FALSE;
stCmd.wAckReq := 0;
stCmd.wShelveReq := 0;
stCmd.wUnshelveReq := 0;

// 2. Вызов слотов и 3. сводка. OutOfService устройства — OutOfService у всех слотов
wAlmActive := 0;
wAlmUnack := 0;
wAlmShelved := 0;
wAlmSuppressed := 0;
ePrioUnack := E_AlarmPriority.None;
FOR uiLoop := 1 TO uiUsed DO
    uiSlot := uiLoop - 1;
    wBit := SHL(WORD#16#0001, uiSlot);
    afbAlarm[uiSlot](xIn := axAlmCond[uiSlot], xSuppress := axAlmSuppress[uiSlot],
                     xOutOfService := (eMode = E_DeviceMode.OutOfService), udiId := udiIdBase + uiSlot,
                     rValue := arAlmValue[uiSlot], stCfg := astCfg[uiSlot], itfTime := itfTimeAct);
    IF afbAlarm[uiSlot].Active THEN
        wAlmActive := wAlmActive OR wBit;
    END_IF
    IF afbAlarm[uiSlot].Unacked THEN
        wAlmUnack := wAlmUnack OR wBit;
        ePrioUnack := MAX(ePrioUnack, afbAlarm[uiSlot].AlarmPriority);
    END_IF
    // наложенные состояния ISA-18.2 — раздельно (ALM-2): отложенные оператором (список отложенных тревог с
    // остатком срока) и подавленные логикой; OutOfService слотов совпадает с режимом устройства (eMode)
    eSlotState := afbAlarm[uiSlot].State;
    IF eSlotState = E_AlarmState.Shelved THEN
        wAlmShelved := wAlmShelved OR wBit;
    ELSIF eSlotState = E_AlarmState.SuppressedByDesign THEN
        wAlmSuppressed := wAlmSuppressed OR wBit;
    END_IF
END_FOR
