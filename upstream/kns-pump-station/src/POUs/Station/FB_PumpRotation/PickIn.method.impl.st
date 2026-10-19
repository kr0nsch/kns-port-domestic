PickIn := 0;
FOR uiIdx := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF NOT axReq[uiIdx] AND axAvail[uiIdx] AND (axReady[uiIdx] OR NOT xRequireReady)
       AND (axCommOk[uiIdx] OR NOT xRequireCommOk) THEN
        IF Better(uiA := uiIdx, uiB := PickIn, eRot := eRot, uiNext := uiNext) THEN
            PickIn := uiIdx;
        END_IF
    END_IF
END_FOR
