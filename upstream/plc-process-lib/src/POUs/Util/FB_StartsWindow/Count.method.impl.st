// 1. Отметки «из будущего» — с конца
xMore := uiUsed > 0;
WHILE xMore DO
    uiLast := (uiNext + GVL_Const.STARTS_WINDOW_MAX - 1) MOD GVL_Const.STARTS_WINDOW_MAX;
    IF altStart[uiLast] > ltNow THEN
        uiNext := uiLast;
        uiUsed := uiUsed - 1;
        xMore := uiUsed > 0;
    ELSE
        xMore := FALSE;
    END_IF
END_WHILE

// 2. Отметки старше окна — с начала. Все оставшиеся <= ltNow: разность без переполнения
xMore := uiUsed > 0;
WHILE xMore DO
    uiFirst := (uiNext + GVL_Const.STARTS_WINDOW_MAX - uiUsed) MOD GVL_Const.STARTS_WINDOW_MAX;
    IF ltNow - altStart[uiFirst] >= GVL_Const.STARTS_WINDOW THEN
        uiUsed := uiUsed - 1;
        xMore := uiUsed > 0;
    ELSE
        xMore := FALSE;
    END_IF
END_WHILE

Count := uiUsed;
