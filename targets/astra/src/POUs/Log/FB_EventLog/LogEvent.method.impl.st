LogEvent := Store(eKind := E_EventKind.Station, ePriority := PL.E_AlarmPriority.None,
                  udiId := GVL_Const.STN_EVENT_ID_BASE + TO_UDINT(eEvent),
                  eOldState := PL.E_AlarmState.Normal, eNewState := PL.E_AlarmState.Normal,
                  eReason := PL.E_AlarmEventReason.None, rValue := rValue);
