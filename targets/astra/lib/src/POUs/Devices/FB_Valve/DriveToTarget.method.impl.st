// 6.7 Движение к цели. Motorized: смена направления в ходе — через Reversing; стоп — Intermediate.
//     Соленоид: смена цели в ходе — сразу другое направление, стопа нет
xMayOpen := xIlkAct OR wPermMissOpen = 0;
xMayClose := xIlkAct OR wPermMissClose = 0;
xEnterMove := FALSE;
//     выбег: встречное направление включается не раньше tReverse после снятия выхода — и после
//     остановки на концевике или по стопу, а не только при смене направления в ходе. Выходы здесь —
//     прошлого вызова; SetOutputs обновляет fbRunOff выходами этого вызова, поэтому отсчёт идёт ровно
//     от снятия выхода
fbRunOff(xIn := xQOpen OR xQClose, tOffDelay := stCfgLkg.tReverse, itfTime := itfTimeAct);
xHoldOpen := xMotorized AND fbRunOff.xOut AND eLastDir = E_ValveState.Closing;
xHoldClose := xMotorized AND fbRunOff.xOut AND eLastDir = E_ValveState.Opening;
//     страгивание с седла (VLV-21): усилие вырыва клина из седла больше усилия хода, муфта открытия срабатывает при
//     ещё замкнутом ZSC — это не заклинивание (в приводах — шунтирование моментного выключателя при страгивании).
//     Муфта открытия не контролируется, пока ZSC замкнут и ещё tLimitFilter после его размыкания (без ZSC — всё
//     окно), но не дольше VLV_UNSEAT_BYPASS от начала открытия с закрытого положения: клин, который не вышел из
//     седла, даёт TorqueTrip. Контроль заклинивания в ходе остаётся
IF eState <> E_ValveState.Opening THEN
    xUnseatArmed := FALSE;
END_IF
fbZscOff(xIn := xAtClose, tOffDelay := stCfgLkg.tLimitFilter, itfTime := itfTimeAct);
fbUnseat(xIn := xUnseatArmed AND eState = E_ValveState.Opening, tOnDelay := GVL_Const.VLV_UNSEAT_BYPASS,
         itfTime := itfTimeAct);
xUnseating := xUnseatArmed AND eState = E_ValveState.Opening AND NOT fbUnseat.xOut
              AND (fbZscOff.xOut OR NOT stCfgLkg.xZscUsed);
IF xDrive THEN
    IF eState = E_ValveState.Opening THEN
        IF xAtOpen THEN
            eState := E_ValveState.Open;
        ELSIF xTrqOpen AND NOT xUnseating THEN
            xFltTorque := TRUE;                // момент раньше концевика: заклинивание
            eState := E_ValveState.Fault;
        ELSIF eTarget = E_ValveState.Closed THEN
            IF xMotorized THEN
                eState := E_ValveState.Reversing;
            ELSIF xMayClose THEN
                eState := E_ValveState.Closing;
                xEnterMove := TRUE;
            END_IF
        ELSIF eTarget = E_ValveState.Intermediate AND xMotorized THEN
            eState := E_ValveState.Intermediate;
        END_IF
    ELSIF eState = E_ValveState.Closing THEN
        IF (xAtClose AND NOT stCfgLkg.xCloseOnTorque)
           OR (stCfgLkg.xCloseOnTorque AND xTrqClose AND (xAtClose OR NOT stCfgLkg.xZscUsed))
        THEN
            // по ZSC; при закрытии «по моменту» (клиновая задвижка) — только по муфте: ZSC стоит чуть
            // раньше посадки клина и выход не снимает, иначе задвижка не дожата. Муфта раньше
            // подключённого ZSC — не посадка, а заклинивание: TorqueTrip ниже
            eState := E_ValveState.Closed;
        ELSIF xTrqClose THEN
            xFltTorque := TRUE;
            eState := E_ValveState.Fault;
        ELSIF eTarget = E_ValveState.Open THEN
            IF xMotorized THEN
                eState := E_ValveState.Reversing;
            ELSIF xMayOpen THEN
                eState := E_ValveState.Opening;
                xEnterMove := TRUE;
            END_IF
        ELSIF eTarget = E_ValveState.Intermediate AND xMotorized THEN
            eState := E_ValveState.Intermediate;
        END_IF
    ELSIF eState = E_ValveState.Reversing THEN
        IF eTarget = E_ValveState.Intermediate THEN
            eState := E_ValveState.Intermediate;
        END_IF
    ELSIF eTarget = E_ValveState.Open AND eState <> E_ValveState.Open AND xMayOpen AND NOT xHoldOpen THEN
        // открытие с закрытого положения — окно страгивания от этого вызова
        xUnseatArmed := eState = E_ValveState.Closed;
        IF xUnseatArmed THEN
            fbUnseat.Preset(xValue := FALSE);
            fbUnseat(xIn := TRUE, tOnDelay := GVL_Const.VLV_UNSEAT_BYPASS, itfTime := itfTimeAct);
        END_IF
        eState := E_ValveState.Opening;
        xEnterMove := TRUE;
    ELSIF eTarget = E_ValveState.Closed AND eState <> E_ValveState.Closed AND xMayClose AND NOT xHoldClose THEN
        eState := E_ValveState.Closing;
        xEnterMove := TRUE;
    END_IF
END_IF
