uiSnapCount := uiCount;
FOR uiI := 1 TO uiSnapCount DO
    GetRecord(uiAge := uiSnapCount - uiI, stRecord => astSnapshot[uiI - 1]);
END_FOR
TakeSnapshot := TRUE;
