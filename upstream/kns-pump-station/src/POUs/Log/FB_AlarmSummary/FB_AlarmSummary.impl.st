itfTimeAct := itfTime;
IF itfTimeAct = 0 THEN
    itfTimeAct := fbSysTime;
END_IF
ltNow := itfTimeAct.Now();

// 1. Счётчики каждый цикл
FOR uiPrio := 1 TO GVL_Const.ALM_PRIO_COUNT DO
    auiActive[uiPrio] := 0;
    auiUnack[uiPrio] := 0;
END_FOR
ePrioUnack := PL.E_AlarmPriority.None;
FOR uiSrc := 1 TO MIN(uiSourceCount, GVL_Const.ALM_SOURCE_MAX) DO
    itfSrc := aitfSource[uiSrc];
    IF itfSrc <> 0 THEN
        // цикл по слотам с 1: при AlarmCount = 0 граница «0 - 1» беззнаковая (правило API 10.5)
        FOR uiK := 1 TO MIN(itfSrc.AlarmCount, GVL_Const.ALM_SRC_SLOT_MAX + 1) DO
            uiSlot := uiK - 1;
            itfAlm := itfSrc.GetAlarm(uiIndex := uiSlot);
            IF itfAlm <> 0 THEN
                eState := itfAlm.State;
                ePrio := itfAlm.AlarmPriority;
                udiSeq := itfAlm.Seq;
                IF udiSeq <> audiSeqPrev[uiSrc, uiSlot] THEN
                    audiSeqPrev[uiSrc, uiSlot] := udiSeq;
                    auliSince[uiSrc, uiSlot] := F_UtcNowMs();
                    alrSince[uiSrc, uiSlot] := PL.F_LTimeToSec(ltIn := ltNow);
                END_IF
                uiPrio := TO_UINT(ePrio);   // индекс Low…Critical = значение приоритета (API 4.1)
                IF uiPrio >= 1 AND uiPrio <= GVL_Const.ALM_PRIO_COUNT THEN
                    IF eState = PL.E_AlarmState.ActiveUnack OR eState = PL.E_AlarmState.ActiveAck THEN
                        auiActive[uiPrio] := auiActive[uiPrio] + 1;
                    END_IF
                    IF eState = PL.E_AlarmState.ActiveUnack OR eState = PL.E_AlarmState.RtnUnack THEN
                        auiUnack[uiPrio] := auiUnack[uiPrio] + 1;
                        ePrioUnack := MAX(ePrioUnack, ePrio);
                    END_IF
                    IF (ePrio = PL.E_AlarmPriority.High OR ePrio = PL.E_AlarmPriority.Critical)
                       AND eState = PL.E_AlarmState.ActiveUnack
                       AND aeStatePrev[uiSrc, uiSlot] <> PL.E_AlarmState.ActiveUnack THEN
                        udiNewHighSeq := udiNewHighSeq + 1;
                    END_IF
                END_IF
                aeStatePrev[uiSrc, uiSlot] := eState;
            END_IF
        END_FOR
    END_IF
END_FOR

// 2. Список тревог раз в ALM_VIEW_PERIOD; «время назад» — пересчёт сразу (LTIME без знака, L7 контракта)
IF NOT xViewInit OR ltNow < ltViewLast OR ltNow - ltViewLast >= TIME_TO_LTIME(GVL_Const.ALM_VIEW_PERIOD) THEN
    xViewInit := TRUE;
    ltViewLast := ltNow;
    BuildView(stView := stView);
END_IF
