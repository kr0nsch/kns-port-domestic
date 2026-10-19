IF uiB = 0 THEN
    Better := TRUE;
ELSIF eRot = E_RotationMode.RunHours THEN
    IF audiHours[uiA] <> audiHours[uiB] THEN
        Better := audiHours[uiA] < audiHours[uiB];
    ELSIF audiStarts[uiA] <> audiStarts[uiB] THEN
        Better := audiStarts[uiA] < audiStarts[uiB];
    ELSE
        Better := uiA < uiB;
    END_IF
ELSIF eRot = E_RotationMode.Cyclic THEN
    uiDistA := (uiA + GVL_Const.STN_PUMP_COUNT - uiNext) MOD GVL_Const.STN_PUMP_COUNT;
    uiDistB := (uiB + GVL_Const.STN_PUMP_COUNT - uiNext) MOD GVL_Const.STN_PUMP_COUNT;
    Better := uiDistA < uiDistB;
ELSE
    Better := uiA < uiB;
END_IF
