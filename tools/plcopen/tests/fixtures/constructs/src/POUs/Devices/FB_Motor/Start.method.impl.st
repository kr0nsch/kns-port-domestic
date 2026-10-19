uiCalls := uiCalls + 1;
IF THIS^.Mode = E_Mode.Auto OR Mode = E_Mode.Manual THEN
    xRun := TRUE;
    uiStarts := uiStarts + 1;
END_IF
Start := xRun;
