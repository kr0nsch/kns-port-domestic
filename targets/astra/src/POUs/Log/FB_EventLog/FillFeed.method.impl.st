stFeed.udiSeqLast := udiSeqLast;
stFeed.udiSeqFirst := udiSeqLast + 1 - UINT_TO_UDINT(uiCount);
stFeed.wReserve := 0;
udiSeq := MAX(stFeed.udiFromSeq, stFeed.udiSeqFirst);
stFeed.uiCount := 0;
FOR uiRow := 1 TO GVL_Const.LOG_FEED_ROWS DO
    IF udiSeq <= udiSeqLast THEN
        // udiSeqLast - udiSeq < uiCount <= LOG_CAPACITY: возраст помещается в UINT
        GetRecord(uiAge := UDINT_TO_UINT(udiSeqLast - udiSeq), stRecord => stFeed.astRow[uiRow]);
        stFeed.uiCount := uiRow;
        udiSeq := udiSeq + 1;
    ELSE
        stFeed.astRow[uiRow] := stEmpty;
    END_IF
END_FOR
