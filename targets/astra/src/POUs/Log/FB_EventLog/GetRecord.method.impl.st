IF uiAge < uiCount THEN
    // uiAge < uiCount <= LOG_CAPACITY: индекс не уходит в минус
    stRecord := astRing[(uiHead + GVL_Const.LOG_CAPACITY - 1 - uiAge) MOD GVL_Const.LOG_CAPACITY];
    GetRecord := TRUE;
ELSE
    stRecord := stEmpty;
    GetRecord := FALSE;
END_IF
