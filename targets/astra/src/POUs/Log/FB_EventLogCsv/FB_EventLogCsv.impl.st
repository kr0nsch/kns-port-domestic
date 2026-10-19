// фронт xExecute в покое или после завершения — новая выгрузка
IF xExecute AND NOT xExecPrev AND (iStep = STEP_IDLE OR iStep = STEP_END) THEN
    eState := E_LogExportState.Writing;
    uiLines := 0;
    udiError := 0;
    xDone := FALSE;
    xError := FALSE;
    xFailed := FALSE;
    uiNext := 0;
    iStep := STEP_OPEN;
END_IF
xExecPrev := xExecute;

// шаги: открыть → порции FILE.Write → закрыть
IF iStep = STEP_OPEN THEN
    fbOpen(xExecute := TRUE, sFileName := sFileName, eFileMode := MODE_WRITE, xExclusive := TRUE);
    IF fbOpen.xError THEN
        udiError := TO_UDINT(fbOpen.eError);
        fbOpen(xExecute := FALSE);
        eState := E_LogExportState.Error;
        xError := TRUE;
        iStep := STEP_END;
    ELSIF fbOpen.xDone THEN
        // fbOpen не вызывается до закрытия файла: hFile держится в его выходе
        udiBufLen := 0;
        AppendText(sText := GVL_Const.LOG_CSV_HEADER);
        iStep := STEP_WRITE;
    END_IF
ELSIF iStep = STEP_WRITE THEN
    IF udiBufLen = 0 THEN
        // порция строк снимка
        FOR uiI := 1 TO GVL_Const.LOG_CSV_LINES_PER_WRITE DO
            IF fbLog.GetSnapshotRecord(uiIndex := uiNext, stRecord => stRec) THEN
                AppendText(sText := F_EventCsvLine(stRecord := stRec));
                uiNext := uiNext + 1;
                uiLines := uiLines + 1;
            END_IF
        END_FOR
    END_IF
    IF udiBufLen = 0 THEN
        iStep := STEP_CLOSE;   // снимок выгружен
    ELSE
        fbWrite(xExecute := TRUE, hFile := fbOpen.hFile, pBuffer := ADR(abBuf), szSize := udiBufLen,
                udiTimeOut := GVL_Const.LOG_CSV_TIMEOUT_US);
        IF fbWrite.xError THEN
            udiError := TO_UDINT(fbWrite.eError);
            fbWrite(xExecute := FALSE);
            xFailed := TRUE;
            iStep := STEP_CLOSE;
        ELSIF fbWrite.xDone THEN
            fbWrite(xExecute := FALSE);
            udiBufLen := 0;
        END_IF
    END_IF
ELSIF iStep = STEP_CLOSE THEN
    fbClose(xExecute := TRUE, hFile := fbOpen.hFile);
    IF fbClose.xDone OR fbClose.xError THEN
        IF fbClose.xError AND NOT xFailed THEN
            udiError := TO_UDINT(fbClose.eError);
            xFailed := TRUE;
        END_IF
        fbClose(xExecute := FALSE);
        fbOpen(xExecute := FALSE);
        xError := xFailed;
        xDone := NOT xFailed;
        eState := SEL(xFailed, E_LogExportState.Done, E_LogExportState.Error);
        iStep := STEP_END;
    END_IF
END_IF
