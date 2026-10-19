// 1. Отказ запрошенного насоса (запрос был в прошлом цикле): Fault или фиксация станции
xFailed := FALSE;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    xAvail := FALSE;
    xFault := FALSE;
    IF aitfPump[uiPump] <> 0 THEN
        xAvail := aitfPump[uiPump].Available;
        xFault := aitfPump[uiPump].Fault;
    END_IF
    xFault := xFault OR axTrip[uiPump];
    IF xEnable AND axRunPrev[uiPump] AND NOT axRemoved[uiPump] AND xFault THEN
        axRemoved[uiPump] := TRUE;
        udiAtsCount := udiAtsCount + 1;
        xFailed := TRUE;
    END_IF
    // насос снят АВР, пока снова не станет доступен — сброшен и в Auto (04 §9.1). Фиксация станции
    // действует на устройство только с его вызова, поэтому без отказа и фиксации, а не только Available
    IF axRemoved[uiPump] AND xAvail AND NOT xFault THEN
        axRemoved[uiPump] := FALSE;
    END_IF
END_FOR

// 2. Окно поиска замены: новый запрос насоса, которого не было в момент отказа (FB_PumpRotation
//    назначает замену в том же цикле, если резерв готов). Снятый АВР насос заменой не бывает: при
//    блокировке станции (недогрузка, перегрев) он ещё доступен и запрошен в цикле отказа
IF xFailed THEN
    xWindow := TRUE;
    fbWindow.Preset(xValue := FALSE);
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        axReqAtAts[uiPump] := axRunPrev[uiPump] AND NOT axRemoved[uiPump];
    END_FOR
END_IF
fbWindow(xIn := xWindow, tOnDelay := GVL_Const.STN_ATS_WINDOW, itfTime := itfTime);
IF xWindow THEN
    uiNewPump := 0;
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        IF uiNewPump = 0 AND axRun[uiPump] AND NOT axReqAtAts[uiPump] AND NOT axRemoved[uiPump] THEN
            uiNewPump := uiPump;
        END_IF
    END_FOR
    IF uiNewPump <> 0 THEN
        xWindow := FALSE;
        IF itfEvents <> 0 THEN
            itfEvents.LogEvent(eEvent := E_StationEvent.AtsPumpIn, rValue := UINT_TO_REAL(uiNewPump));
        END_IF
    ELSIF fbWindow.xOut OR NOT xEnable THEN
        xWindow := FALSE;                               // заменить нечем: KNS1.LACK по своему условию
    END_IF
END_IF

// 3. Сводные условия
xAtsActive := FALSE;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    xAtsActive := xAtsActive OR axRemoved[uiPump];
    axRunPrev[uiPump] := axRun[uiPump];
END_FOR
xLack := uiRequired > uiAvailable + uiForeign;
// резерв — сверх насосов обычного режима: ступенчатое и ПИД работают не больше чем MIN(uiDutyMax, STN_DUTY_MAX)
xNoReserve := uiAvailable < MIN(stCfg.uiDutyMax, GVL_Const.STN_DUTY_MAX) + 1;
