F_ZeroPad := UDINT_TO_STRING(udiValue);
FOR uiI := INT_TO_UINT(LEN(F_ZeroPad)) + 1 TO MIN(uiDigits, INT_TO_UINT(GVL_Const.LOG_NUM_LEN)) DO
    F_ZeroPad := CONCAT('0', F_ZeroPad);
END_FOR
