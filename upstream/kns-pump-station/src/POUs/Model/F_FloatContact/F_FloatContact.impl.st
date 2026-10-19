IF xHighFloat THEN
    xTripped := rLevel_m >= rMark_m;
ELSE
    xTripped := rLevel_m <= rMark_m;
END_IF

CASE eStuck OF
    E_SimFloatStuck.StuckNormal:
        xTripped := FALSE;
    E_SimFloatStuck.StuckTripped:
        xTripped := TRUE;
ELSE
    // None: контакт по уровню
END_CASE

F_FloatContact := NOT xTripped;
