FOR uiLoop := 1 TO GVL_Const.DEV_ALARMS_MAX DO
    ePrio := astCfg[uiLoop - 1].ePriority;
    xOk := xOk AND (ePrio = E_AlarmPriority.None OR ePrio = E_AlarmPriority.Low OR ePrio = E_AlarmPriority.Medium
                    OR ePrio = E_AlarmPriority.High OR ePrio = E_AlarmPriority.Critical);
END_FOR
CheckAlarmCfg := xOk;
