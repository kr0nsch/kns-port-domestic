PickLeadIn := 0;
FOR uiIdx := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF axReq[uiIdx] AND (axCommOk[uiIdx] OR NOT xCommOnly) THEN
        IF Better(uiA := uiIdx, uiB := PickLeadIn, eRot := E_RotationMode.RunHours, uiNext := 1) THEN
            PickLeadIn := uiIdx;
        END_IF
    END_IF
END_FOR
