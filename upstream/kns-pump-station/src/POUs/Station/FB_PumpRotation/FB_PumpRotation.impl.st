// 0. Время вызова и снимок насосов (04 §5.1): доступные, работающие, сторонние (работают не в Auto)
IF itfTime <> 0 THEN
    ltNow := itfTime.Now();
ELSE
    ltNow := fbSysTime.Now();
END_IF
uiAvailable := 0;
uiRunning := 0;
uiForeign := 0;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF aitfPump[uiPump] <> 0 THEN
        axAvail[uiPump] := aitfPump[uiPump].Available;
        axRunning[uiPump] := aitfPump[uiPump].Running;
        axReady[uiPump] := aitfPump[uiPump].ReadyToStart;
        audiHours[uiPump] := aitfPump[uiPump].RunSeconds;
        audiStarts[uiPump] := aitfPump[uiPump].Starts;
        audiCurRun[uiPump] := aitfPump[uiPump].CurrentRunSeconds;
        ePumpMode := aitfPump[uiPump].Mode;
    ELSE
        axAvail[uiPump] := FALSE;
        axRunning[uiPump] := FALSE;
        axReady[uiPump] := FALSE;
        audiHours[uiPump] := 0;
        audiStarts[uiPump] := 0;
        audiCurRun[uiPump] := 0;
        ePumpMode := PL.E_DeviceMode.OutOfService;
    END_IF
    IF axAvail[uiPump] THEN
        uiAvailable := uiAvailable + 1;
    END_IF
    IF axRunning[uiPump] THEN
        uiRunning := uiRunning + 1;
    END_IF
    axForeign[uiPump] := axRunning[uiPump] AND ePumpMode <> PL.E_DeviceMode.Auto;
END_FOR

// Следующий ведущий (Cyclic) вне 1…STN_PUMP_COUNT — мусор persistent-памяти: с первого насоса
IF stRetain.uiNextLead < 1 OR stRetain.uiNextLead > GVL_Const.STN_PUMP_COUNT THEN
    stRetain.uiNextLead := 1;
END_IF

udiMaxRun_s := TIME_TO_UDINT(stCfg.tMaxContRun) / GVL_Const.STN_MS_PER_S;

IF NOT xEnable THEN
    // 1. «Ручной»: запросов нет, передача роли прервана; роли считаются (Standby/None)
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        axReq[uiPump] := FALSE;
    END_FOR
    uiLeadIdx := 0;
    xHoActive := FALSE;
    xHoRetryWait := FALSE;
    xStaggerArmed := FALSE;
    uiForeign := 0;
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        IF axForeign[uiPump] THEN
            uiForeign := uiForeign + 1;
        END_IF
    END_FOR
    uiTarget := 0;
ELSE
    // 2. Подхват работающих насосов (вход в «Автомат», смена управления, старт ПЛК): запрос
    //    получают работающие, прежние запросы сохраняются — пуск, который ещё идёт, не обрывается.
    //    В этом вызове доступность не проверяется: устройство ещё не выполнило запрос режима
    IF xAdopt THEN
        FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
            IF axAdoptRun[uiPump] AND NOT axReq[uiPump] THEN
                axReq[uiPump] := TRUE;
                udiReqSeq := udiReqSeq + 1;
                audiReqSeq[uiPump] := udiReqSeq;
            END_IF
        END_FOR
    ELSE
        // Насос, ставший недоступным (отказ, блокировка, смена режима, нет напряжения), теряет
        // запрос сразу; после сброса он резервный (АВР — FB_Ats, 04 §9)
        FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
            IF axReq[uiPump] AND NOT axAvail[uiPump] THEN
                axReq[uiPump] := FALSE;
            END_IF
        END_FOR
    END_IF

    // 3. Ведущий снят — роль получает работающий по запросу насос (подпорный → ведущий, 04 §5.2)
    IF uiLeadIdx >= 1 AND uiLeadIdx <= GVL_Const.STN_PUMP_COUNT THEN
        IF NOT axReq[uiLeadIdx] THEN
            uiLeadIdx := 0;
        END_IF
    ELSE
        uiLeadIdx := 0;
    END_IF
    IF uiLeadIdx = 0 THEN
        uiLeadIdx := PickLead(xPreferComm := xRequireComm);
    END_IF

    // 4. ПИД: ведущий без связи, а у другого запрошенного насоса связь есть — смена ведущего без
    //    пуска и останова (оба получают одно задание частоты, 04 §12)
    IF xRequireComm AND uiLeadIdx <> 0 THEN
        IF NOT axCommOk[uiLeadIdx] THEN
            uiPick := PickLeadIn(xCommOnly := TRUE);
            IF uiPick <> 0 THEN
                uiLeadIdx := uiPick;
            END_IF
        END_IF
    END_IF

    uiCount := 0;
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        IF axReq[uiPump] THEN
            uiCount := uiCount + 1;
        END_IF
    END_FOR
    // Запросов нужно: требуемое число минус сторонние работающие (04 §5.1), не меньше 0. Сторонний —
    // работает не в Auto и не запрошен станцией: подхваченный насос, который ещё не перешёл в Auto
    // (запрос режима выполнит устройство), сторонним не считается
    uiForeign := 0;
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        IF axForeign[uiPump] AND NOT axReq[uiPump] THEN
            uiForeign := uiForeign + 1;
        END_IF
    END_FOR
    uiTarget := MIN(uiRequired, GVL_Const.STN_PUMP_COUNT);
    uiTarget := SEL(uiTarget > uiForeign, 0, uiTarget - uiForeign);

    // 5. Передача роли (04 §8.2): прервать, если условия изменились или замена отказала
    IF xHoActive THEN
        IF NOT xHandoverAllowed OR uiTarget <> uiHoTarget OR NOT axReq[uiHoOld] OR NOT axReq[uiHoNew] THEN
            xHoActive := FALSE;
            // замена потеряла запрос (отказ при пуске, АВР) — прежний насос работает, повтор позже
            xHoRetryWait := axReq[uiHoOld] AND NOT axReq[uiHoNew];
        END_IF
    END_IF
END_IF

// Выдержки передачи роли вызываются каждый цикл (FB_Delay должен видеть каждую смену входа)
xHoNewRunning := FALSE;
IF xHoActive AND uiHoNew >= 1 AND uiHoNew <= GVL_Const.STN_PUMP_COUNT THEN
    xHoNewRunning := axRunning[uiHoNew];
END_IF
fbHoStart(xIn := xHoActive AND NOT xHoNewRunning, tOnDelay := GVL_Const.STN_HANDOVER_START_TIMEOUT,
          itfTime := itfTime);
fbHoOverlap(xIn := xHoActive AND xHoNewRunning, tOnDelay := stCfg.tOverlap, itfTime := itfTime);

IF xEnable THEN
    IF xHoActive THEN
        IF fbHoStart.xOut THEN
            // замена не вышла в работу: запрос с неё снимается, прежний насос работает дальше
            axReq[uiHoNew] := FALSE;
            uiCount := uiCount - 1;
            xHoActive := FALSE;
            xHoRetryWait := TRUE;
        ELSIF fbHoOverlap.xOut THEN
            // замена в работе дольше tOverlap: она получает роль прежнего насоса, тот останавливается
            IF uiLeadIdx = uiHoOld THEN
                uiLeadIdx := uiHoNew;
            END_IF
            axReq[uiHoOld] := FALSE;
            uiCount := uiCount - 1;
            xHoActive := FALSE;
            IF itfEvents <> 0 THEN
                itfEvents.LogEvent(eEvent := E_StationEvent.ContRunHandover, rValue := UINT_TO_REAL(uiHoNew));
            END_IF
        END_IF
    ELSIF xHandoverAllowed AND stCfg.tMaxContRun > T#0S AND NOT xHoRetryWait AND uiCount = uiTarget THEN
        // насос с запросом работает непрерывно дольше tMaxContRun (берётся самый долгий)
        uiPick := 0;
        FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
            IF axReq[uiPump] AND axRunning[uiPump] AND audiCurRun[uiPump] >= udiMaxRun_s THEN
                IF uiPick = 0 THEN
                    uiPick := uiPump;
                ELSIF audiCurRun[uiPump] > audiCurRun[uiPick] THEN
                    uiPick := uiPump;
                END_IF
            END_IF
        END_FOR
        IF uiPick <> 0 THEN
            uiHoOld := uiPick;
            // замена — только готовый к пуску резервный; ведущему в ПИД — со связью
            uiHoNew := PickCandidate(eRot := stCfg.eRotation, uiNext := stRetain.uiNextLead,
                                     xNeedComm := xRequireComm AND uiPick = uiLeadIdx, xReadyOnly := TRUE);
            IF uiHoNew <> 0 THEN
                axReq[uiHoNew] := TRUE;
                udiReqSeq := udiReqSeq + 1;
                audiReqSeq[uiHoNew] := udiReqSeq;
                uiCount := uiCount + 1;
                xHoActive := TRUE;
                uiHoTarget := uiTarget;
                xStaggerArmed := TRUE;
                ltLastNewReq := ltNow;
                uiLastNewPump := uiHoNew;
            ELSE
                xHoRetryWait := TRUE;                       // резерва нет — повтор через STN_HANDOVER_RETRY
            END_IF
        END_IF
    END_IF

    // 6. Снятие лишних запросов (04 §5.2): RunHours — насос с большей наработкой, Cyclic/Fixed —
    //    подпорный; во время передачи роли запрос замены не лишний
    IF NOT xHoActive THEN
        FOR uiStep := 1 TO GVL_Const.STN_PUMP_COUNT DO
            IF uiCount > uiTarget THEN
                uiPick := PickToRemove(eRot := stCfg.eRotation);
                IF uiPick <> 0 THEN
                    axReq[uiPick] := FALSE;
                    uiCount := uiCount - 1;
                    IF uiPick = uiLeadIdx THEN
                        uiLeadIdx := PickLead(xPreferComm := xRequireComm);
                    END_IF
                END_IF
            END_IF
        END_FOR
    END_IF

    // 7. Новые запросы: не больше нужного, новые — не больше uiRequestLimit (последовательный пуск),
    //    по одному с интервалом tStagger, если насос предыдущего нового запроса ещё запрошен.
    //    «Время назад» — интервал отсчитывается заново (два пуска подряд не допускаются)
    IF ltNow < ltLastNewReq THEN
        ltLastNewReq := ltNow;
    END_IF
    FOR uiStep := 1 TO GVL_Const.STN_PUMP_COUNT DO
        xStaggerOk := TRUE;
        IF xStaggerArmed AND uiLastNewPump >= 1 AND uiLastNewPump <= GVL_Const.STN_PUMP_COUNT THEN
            IF axReq[uiLastNewPump] THEN
                xStaggerOk := ltNow - ltLastNewReq >= TIME_TO_LTIME(stCfg.tStagger);
            END_IF
        END_IF
        IF NOT xHoActive AND uiCount < uiTarget AND uiCount < uiRequestLimit AND xStaggerOk THEN
            uiPick := PickCandidate(eRot := stCfg.eRotation, uiNext := stRetain.uiNextLead,
                                    xNeedComm := xRequireComm AND uiLeadIdx = 0, xReadyOnly := FALSE);
            IF uiPick <> 0 THEN
                axReq[uiPick] := TRUE;
                udiReqSeq := udiReqSeq + 1;
                audiReqSeq[uiPick] := udiReqSeq;
                uiCount := uiCount + 1;
                xStaggerArmed := TRUE;
                ltLastNewReq := ltNow;
                uiLastNewPump := uiPick;
                IF uiLeadIdx = 0 THEN
                    // новый ведущий; по кругу — следующий после него (энергонезависимо)
                    uiLeadIdx := uiPick;
                    IF stCfg.eRotation = E_RotationMode.Cyclic THEN
                        stRetain.uiNextLead := (uiPick MOD GVL_Const.STN_PUMP_COUNT) + 1;
                    END_IF
                END_IF
            END_IF
        END_IF
    END_FOR

    // ожидание интервала пусков (HMI): нужен ещё насос, кандидат есть, но tStagger не истёк
    xStaggerOk := TRUE;
    IF xStaggerArmed AND uiLastNewPump >= 1 AND uiLastNewPump <= GVL_Const.STN_PUMP_COUNT THEN
        IF axReq[uiLastNewPump] THEN
            xStaggerOk := ltNow - ltLastNewReq >= TIME_TO_LTIME(stCfg.tStagger);
        END_IF
    END_IF
    xStaggerWait := FALSE;
    IF NOT xHoActive AND uiCount < uiTarget AND uiCount < uiRequestLimit AND NOT xStaggerOk THEN
        xStaggerWait := PickCandidate(eRot := stCfg.eRotation, uiNext := stRetain.uiNextLead,
                                      xNeedComm := FALSE, xReadyOnly := FALSE) <> 0;
    END_IF
ELSE
    xStaggerWait := FALSE;
END_IF

fbHoRetry(xIn := xHoRetryWait, tOnDelay := GVL_Const.STN_HANDOVER_RETRY, itfTime := itfTime);
IF fbHoRetry.xOut THEN
    xHoRetryWait := FALSE;
END_IF

// 8. Выходы: запросы, роли (04 §5.1), счётчики; событие смены ведущего (101005, номер насоса)
uiRequests := 0;
uiRunningRequested := 0;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    axRun[uiPump] := axReq[uiPump];
    IF axReq[uiPump] THEN
        uiRequests := uiRequests + 1;
        IF axRunning[uiPump] THEN
            uiRunningRequested := uiRunningRequested + 1;
        END_IF
        IF uiPump = uiLeadIdx THEN
            aeRole[uiPump] := E_PumpRole.Lead;
        ELSE
            aeRole[uiPump] := E_PumpRole.Assist;
        END_IF
    ELSIF axAvail[uiPump] THEN
        aeRole[uiPump] := E_PumpRole.Standby;
    ELSE
        aeRole[uiPump] := E_PumpRole.None;
    END_IF
END_FOR
uiLead := uiLeadIdx;
xHandover := xHoActive;
// По кругу следующий ведущий отсчитывается от любого нового ведущего — и без пуска (передача роли, подпорный
// стал ведущим, подхват): иначе тот же насос снова получил бы следующий пуск (04 §8.1)
IF uiLeadIdx <> uiLeadPrev AND uiLeadIdx <> 0 THEN
    IF stCfg.eRotation = E_RotationMode.Cyclic THEN
        stRetain.uiNextLead := (uiLeadIdx MOD GVL_Const.STN_PUMP_COUNT) + 1;
    END_IF
    IF itfEvents <> 0 THEN
        itfEvents.LogEvent(eEvent := E_StationEvent.LeadChanged, rValue := UINT_TO_REAL(uiLeadIdx));
    END_IF
END_IF
uiLeadPrev := uiLeadIdx;
