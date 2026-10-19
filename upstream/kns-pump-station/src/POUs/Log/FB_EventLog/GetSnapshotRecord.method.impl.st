IF uiIndex < uiSnapCount THEN
    stRecord := astSnapshot[uiIndex];
    GetSnapshotRecord := TRUE;
ELSE
    stRecord := stEmpty;
    GetSnapshotRecord := FALSE;
END_IF
