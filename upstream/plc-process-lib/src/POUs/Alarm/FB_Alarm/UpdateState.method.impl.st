// 7. Наложенные состояния по старшинству OutOfService > SuppressedByDesign > Shelved.
//    Вход — из любого состояния ниже по старшинству (неквитированность сбрасывается),
//    выход — в следующее по старшинству или в базовое: условие активно ? ActiveUnack : Normal
IF xOutOfService THEN
    IF eState <> E_AlarmState.OutOfService THEN
        Transit(eNew := E_AlarmState.OutOfService, eReason := E_AlarmEventReason.OosOn);
    END_IF
ELSIF eState = E_AlarmState.OutOfService THEN
    IF xSuppress THEN
        Transit(eNew := E_AlarmState.SuppressedByDesign, eReason := E_AlarmEventReason.OosOff);
    ELSE
        Transit(eNew := ReleaseState(), eReason := E_AlarmEventReason.OosOff);
    END_IF
ELSIF xSuppress THEN
    IF eState <> E_AlarmState.SuppressedByDesign THEN
        Transit(eNew := E_AlarmState.SuppressedByDesign, eReason := E_AlarmEventReason.Suppressed);
    END_IF
ELSIF eState = E_AlarmState.SuppressedByDesign THEN
    Transit(eNew := ReleaseState(), eReason := E_AlarmEventReason.Unsuppressed);
ELSIF xShelved THEN
    IF eState <> E_AlarmState.Shelved THEN
        Transit(eNew := E_AlarmState.Shelved, eReason := E_AlarmEventReason.Shelved);
    END_IF
ELSIF eState = E_AlarmState.Shelved THEN
    // shelve закончился в этом вызове: командой (Unshelved) или по сроку (ShelveExpired)
    IF eShelveEnd = E_AlarmEventReason.Unshelved THEN
        Transit(eNew := ReleaseState(), eReason := E_AlarmEventReason.Unshelved);
    ELSE
        Transit(eNew := ReleaseState(), eReason := E_AlarmEventReason.ShelveExpired);
    END_IF
// 8. Базовый автомат ISA-18.2
ELSIF eState = E_AlarmState.Normal OR eState = E_AlarmState.RtnUnack THEN
    IF xActive THEN
        Transit(eNew := E_AlarmState.ActiveUnack, eReason := E_AlarmEventReason.Activated);
    END_IF
ELSIF eState = E_AlarmState.ActiveUnack THEN
    IF NOT xActive THEN
        Transit(eNew := E_AlarmState.RtnUnack, eReason := E_AlarmEventReason.Cleared);
    END_IF
ELSIF eState = E_AlarmState.ActiveAck THEN
    IF NOT xActive THEN
        Transit(eNew := E_AlarmState.Normal, eReason := E_AlarmEventReason.Cleared);
    END_IF
END_IF
