stView.uiCount := uiCount;
stView.uiPageCount := MAX(1, (uiCount + GVL_Const.LOG_VIEW_ROWS - 1) / GVL_Const.LOG_VIEW_ROWS);
IF stView.uiPage >= stView.uiPageCount THEN
    stView.uiPage := stView.uiPageCount - 1;
END_IF
stView.wReserve := 0;
uiAgeFirst := stView.uiPage * GVL_Const.LOG_VIEW_ROWS;
FOR uiRow := 1 TO GVL_Const.LOG_VIEW_ROWS DO
    GetRecord(uiAge := uiAgeFirst + uiRow - 1, stRecord => stView.astRow[uiRow]);
END_FOR
