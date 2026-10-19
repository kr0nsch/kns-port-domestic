iCount := 0;
uiTotal := 0;
FOR uiSrc := 1 TO MIN(uiSourceCount, GVL_Const.ALM_SOURCE_MAX) DO
    itfSrc := aitfSource[uiSrc];
    IF itfSrc <> 0 THEN
        FOR uiK := 1 TO MIN(itfSrc.AlarmCount, GVL_Const.ALM_SRC_SLOT_MAX + 1) DO
            uiSlot := uiK - 1;
            itfAlm := itfSrc.GetAlarm(uiIndex := uiSlot);
            IF itfAlm <> 0 THEN
                eState := itfAlm.State;
                IF eState <> PL.E_AlarmState.Normal THEN
                    uiTotal := uiTotal + 1;
                    IF eState = PL.E_AlarmState.ActiveUnack OR eState = PL.E_AlarmState.RtnUnack THEN
                        iGroup := 0;
                    ELSIF eState = PL.E_AlarmState.ActiveAck THEN
                        iGroup := 1;
                    ELSE
                        iGroup := 2;   // Shelved, SuppressedByDesign, OutOfService
                    END_IF
                    iPrio := TO_INT(itfAlm.AlarmPriority);
                    lrTime := alrSince[uiSrc, uiSlot];
                    // позиция: верхняя строка, перед которой встаёт новая (группа, приоритет, новее)
                    iPos := iCount + 1;
                    FOR iJ := iCount TO 1 BY -1 DO
                        IF iGroup < aiGroup[iJ]
                           OR (iGroup = aiGroup[iJ] AND iGroup < 2 AND iPrio > aiPrio[iJ])
                           OR (iGroup = aiGroup[iJ] AND (iGroup = 2 OR iPrio = aiPrio[iJ])
                               AND lrTime > alrTime[iJ]) THEN
                            iPos := iJ;
                        END_IF
                    END_FOR
                    IF iPos <= UINT_TO_INT(GVL_Const.ALM_VIEW_ROWS) THEN
                        // сдвиг вниз; в полном списке последняя строка выпадает
                        IF iCount < UINT_TO_INT(GVL_Const.ALM_VIEW_ROWS) THEN
                            iCount := iCount + 1;
                        END_IF
                        FOR iJ := iCount TO iPos + 1 BY -1 DO
                            stView.astRow[iJ] := stView.astRow[iJ - 1];
                            aiGroup[iJ] := aiGroup[iJ - 1];
                            aiPrio[iJ] := aiPrio[iJ - 1];
                            alrTime[iJ] := alrTime[iJ - 1];
                        END_FOR
                        stView.astRow[iPos].udiId := itfAlm.Id;
                        stView.astRow[iPos].ePriority := itfAlm.AlarmPriority;
                        stView.astRow[iPos].eState := eState;
                        stView.astRow[iPos].uiSource := uiSrc;
                        stView.astRow[iPos].uiSlot := uiSlot;
                        stView.astRow[iPos].uliSinceUtc_ms := auliSince[uiSrc, uiSlot];
                        aiGroup[iPos] := iGroup;
                        aiPrio[iPos] := iPrio;
                        alrTime[iPos] := lrTime;
                    END_IF
                END_IF
            END_IF
        END_FOR
    END_IF
END_FOR
FOR iJ := iCount + 1 TO UINT_TO_INT(GVL_Const.ALM_VIEW_ROWS) DO
    stView.astRow[iJ] := stEmpty;
END_FOR
stView.uiCount := INT_TO_UINT(iCount);
stView.uiActiveTotal := uiTotal;
stView.udiRevision := stView.udiRevision + 1;
