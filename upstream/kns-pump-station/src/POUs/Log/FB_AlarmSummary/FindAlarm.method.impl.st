FindAlarm := 0;
FOR uiSrc := 1 TO MIN(uiSourceCount, GVL_Const.ALM_SOURCE_MAX) DO
    itfSrc := aitfSource[uiSrc];
    IF itfSrc <> 0 THEN
        FOR uiK := 1 TO MIN(itfSrc.AlarmCount, GVL_Const.ALM_SRC_SLOT_MAX + 1) DO
            itfAlm := itfSrc.GetAlarm(uiIndex := uiK - 1);
            IF itfAlm <> 0 THEN
                IF itfAlm.Id = udiId THEN
                    FindAlarm := itfAlm;
                    RETURN;
                END_IF
            END_IF
        END_FOR
    END_IF
END_FOR
