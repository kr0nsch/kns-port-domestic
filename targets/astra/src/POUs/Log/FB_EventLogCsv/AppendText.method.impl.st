pChar := ADR(sText);
FOR iI := 1 TO LEN(sText) DO
    IF udiBufLen < GVL_Const.LOG_CSV_BUF_LEN THEN
        abBuf[udiBufLen] := pChar^;
        udiBufLen := udiBufLen + 1;
    END_IF
    pChar := pChar + 1;
END_FOR
