IF xShelved THEN
    ReleaseState := E_AlarmState.Shelved;
ELSIF xActive THEN
    ReleaseState := E_AlarmState.ActiveUnack;
ELSE
    ReleaseState := E_AlarmState.Normal;
END_IF
