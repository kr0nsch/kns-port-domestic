F_MbStatusOk_Regul := FALSE;
IF iStatus >= 0 AND iStatus <= GVL_ConstRegul.MB_STATUS_MAX THEN
    F_MbStatusOk_Regul := GVL_ConstRegul.MB_STATUS_OK[iStatus];
END_IF
