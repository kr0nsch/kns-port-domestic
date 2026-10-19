// Поля — по порядку раздела 18.2: номер растёт на 1 от поля к полю, первое отличие запоминается
ChangedParam := 0;
uiNo := GVL_Const.STN_CFG_PARAM_FIRST;
IF stNew.rLvlStop_m <> stOld.rLvlStop_m THEN
    ChangedParam := uiNo;                                           // № 2
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLvlStartLead_m <> stOld.rLvlStartLead_m THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLvlStopAssist_m <> stOld.rLvlStopAssist_m THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLvlStartAssist_m <> stOld.rLvlStartAssist_m THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tLvlConfirm <> stOld.tLvlConfirm THEN
    ChangedParam := uiNo;                                           // № 6
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rStepSpeed_pct <> stOld.rStepSpeed_pct THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLevelSp_m <> stOld.rLevelSp_m THEN
    ChangedParam := uiNo;                                           // № 8
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rAssistOn_pct <> stOld.rAssistOn_pct THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tAssistOn <> stOld.tAssistOn THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rAssistOff_pct <> stOld.rAssistOff_pct THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tAssistOff <> stOld.tAssistOff THEN
    ChangedParam := uiNo;                                           // № 12
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.uiDutyMax <> stOld.uiDutyMax THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.eRotation <> stOld.eRotation THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tMaxContRun <> stOld.tMaxContRun THEN
    ChangedParam := uiNo;                                           // № 15
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tOverlap <> stOld.tOverlap THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tStagger <> stOld.tStagger THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tPwrRestart <> stOld.tPwrRestart THEN
    ChangedParam := uiNo;                                           // № 18
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tSeqStep <> stOld.tSeqStep THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tPlcStart <> stOld.tPlcStart THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tDryRelease <> stOld.tDryRelease THEN
    ChangedParam := uiNo;                                           // № 21
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLdev102On_m <> stOld.rLdev102On_m THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLdev102Off_m <> stOld.rLdev102Off_m THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLdev103On_m <> stOld.rLdev103On_m THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rLdev103Off_m <> stOld.rLdev103Off_m THEN
    ChangedParam := uiNo;                                           // № 25
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tLdev <> stOld.tLdev THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tLtRecover <> stOld.tLtRecover THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rUnderload_A <> stOld.rUnderload_A THEN
    ChangedParam := uiNo;                                           // № 28
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.rUnderloadSpeed_pct <> stOld.rUnderloadSpeed_pct THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tUnderload <> stOld.tUnderload THEN
    ChangedParam := uiNo;
END_IF
uiNo := uiNo + 1;
IF ChangedParam = 0 AND stNew.tV1Overrun <> stOld.tV1Overrun THEN
    ChangedParam := uiNo;                                           // № 31
END_IF

// Таблица тревог и резерв — один номер
IF ChangedParam = 0 THEN
    FOR uiIdx := 1 TO GVL_Const.STN_ALARM_COUNT DO
        IF stNew.astAlarm[uiIdx].ePriority <> stOld.astAlarm[uiIdx].ePriority
           OR stNew.astAlarm[uiIdx].tOnDelay <> stOld.astAlarm[uiIdx].tOnDelay
           OR stNew.astAlarm[uiIdx].tOffDelay <> stOld.astAlarm[uiIdx].tOffDelay
           OR stNew.astAlarm[uiIdx].tShelveMax <> stOld.astAlarm[uiIdx].tShelveMax THEN
            ChangedParam := GVL_Const.STN_CFG_PARAM_ALARMS;
        END_IF
    END_FOR
    FOR uiIdx := 0 TO GVL_Const.STN_CFG_RESERVE_REAL_LAST DO
        IF stNew.arReserve[uiIdx] <> stOld.arReserve[uiIdx] THEN
            ChangedParam := GVL_Const.STN_CFG_PARAM_ALARMS;
        END_IF
    END_FOR
    FOR uiIdx := 0 TO GVL_Const.STN_CFG_RESERVE_SHORT_LAST DO
        IF stNew.atReserve[uiIdx] <> stOld.atReserve[uiIdx] OR stNew.auiReserve[uiIdx] <> stOld.auiReserve[uiIdx] THEN
            ChangedParam := GVL_Const.STN_CFG_PARAM_ALARMS;
        END_IF
    END_FOR
END_IF
