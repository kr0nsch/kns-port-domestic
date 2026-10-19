// 1. Отметки новее регистрируемой (было «время назад») удаляются: кольцо остаётся упорядоченным
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

// 2. Запись; заполненное кольцо затирает самую старую отметку
altStart[uiNext] := ltNow;
uiNext := (uiNext + 1) MOD GVL_Const.STARTS_WINDOW_MAX;
uiUsed := MIN(uiUsed + 1, GVL_Const.STARTS_WINDOW_MAX);
