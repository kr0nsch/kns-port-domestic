wErr := 0;

// Уровни. Зазоры (сумма двух REAL) сравниваются с допуском STN_CFG_EPS: введённые 1,00 и 1,30
// дают ровно зазор 0,30, хотя двоичное представление чуть меньше. Сравнения с NaN ложны — неконечное
// значение не проходит ни одну проверку
IF NOT (GVL_Const.STN_LS103_MARK_M < rLvlL_m AND rLvlL_m < stCfg.rLvlStop_m
        AND stCfg.rLvlStop_m < stCfg.rLvlStopAssist_m AND stCfg.rLvlStopAssist_m < stCfg.rLvlStartLead_m
        AND stCfg.rLvlStartLead_m < stCfg.rLvlStartAssist_m AND stCfg.rLvlStartAssist_m < rLvlH_m
        AND rLvlH_m < GVL_Const.STN_LS102_MARK_M) THEN
    wErr := wErr OR GVL_Const.STN_CFG_LEVEL_ORDER;
END_IF
IF NOT (stCfg.rLvlStop_m >= GVL_Const.STN_LVL_STOP_MIN_M AND stCfg.rLvlStop_m <= GVL_Const.STN_LVL_STOP_MAX_M
        AND stCfg.rLvlStartLead_m >= stCfg.rLvlStop_m + GVL_Const.STN_LVL_GAP_M - GVL_Const.STN_CFG_EPS
        AND stCfg.rLvlStartLead_m <= GVL_Const.STN_LVL_START_LEAD_MAX_M
        AND stCfg.rLvlStopAssist_m >= stCfg.rLvlStop_m
        AND stCfg.rLvlStopAssist_m <= stCfg.rLvlStartAssist_m - GVL_Const.STN_LVL_GAP_M + GVL_Const.STN_CFG_EPS
        AND stCfg.rLvlStartAssist_m >= stCfg.rLvlStartLead_m + GVL_Const.STN_LVL_GAP_M - GVL_Const.STN_CFG_EPS
        AND stCfg.rLvlStartAssist_m <= GVL_Const.STN_LVL_START_ASSIST_MAX_M) THEN
    wErr := wErr OR GVL_Const.STN_CFG_LEVEL_RANGE;
END_IF

// Ступенчатое: частота
IF NOT (stCfg.rStepSpeed_pct >= GVL_Const.STN_STEP_SPEED_MIN_PCT AND stCfg.rStepSpeed_pct <= PL.GVL_Const.PCT_FULL) THEN
    wErr := wErr OR GVL_Const.STN_CFG_SPEED;
END_IF

// ПИД: подключение и отключение подпорного
IF NOT (stCfg.rAssistOn_pct >= GVL_Const.STN_ASSIST_ON_MIN_PCT AND stCfg.rAssistOn_pct <= PL.GVL_Const.PCT_FULL
        AND stCfg.tAssistOn >= GVL_Const.STN_ASSIST_ON_T_MIN AND stCfg.tAssistOn <= GVL_Const.STN_ASSIST_ON_T_MAX
        AND stCfg.rAssistOff_pct >= GVL_Const.STN_ASSIST_OFF_MIN_PCT
        AND stCfg.rAssistOff_pct <= stCfg.rAssistOn_pct - GVL_Const.STN_ASSIST_GAP_PCT + GVL_Const.STN_CFG_EPS
        AND stCfg.tAssistOff >= GVL_Const.STN_ASSIST_OFF_T_MIN
        AND stCfg.tAssistOff <= GVL_Const.STN_ASSIST_OFF_T_MAX) THEN
    wErr := wErr OR GVL_Const.STN_CFG_PID_STAGING;
END_IF

// Задание уровня — в пределах задания LIC101
IF NOT (stCfg.rLevelSp_m >= stPidCfg.rSpMin_eu AND stCfg.rLevelSp_m <= stPidCfg.rSpMax_eu) THEN
    wErr := wErr OR GVL_Const.STN_CFG_SETPOINT;
END_IF

// Роли
IF stCfg.uiDutyMax < GVL_Const.STN_DUTY_MIN OR stCfg.uiDutyMax > GVL_Const.STN_PUMP_COUNT THEN
    wErr := wErr OR GVL_Const.STN_CFG_DUTY;
END_IF
IF (stCfg.eRotation <> E_RotationMode.RunHours AND stCfg.eRotation <> E_RotationMode.Cyclic
    AND stCfg.eRotation <> E_RotationMode.Fixed)
   OR (stCfg.tMaxContRun <> T#0S AND (stCfg.tMaxContRun < GVL_Const.STN_MAX_CONT_RUN_MIN
                                      OR stCfg.tMaxContRun > GVL_Const.STN_MAX_CONT_RUN_MAX))
   OR stCfg.tOverlap > GVL_Const.STN_OVERLAP_MAX OR stCfg.tStagger > GVL_Const.STN_STAGGER_MAX THEN
    wErr := wErr OR GVL_Const.STN_CFG_ROTATION;
END_IF

// Выдержки: питание, сухой ход без уровнемера, возврат к LT101, подтверждение уровня, выбег В1
IF stCfg.tPwrRestart > GVL_Const.STN_PWR_RESTART_MAX
   OR stCfg.tSeqStep < GVL_Const.STN_SEQ_STEP_MIN OR stCfg.tSeqStep > GVL_Const.STN_SEQ_STEP_MAX
   OR stCfg.tPlcStart > GVL_Const.STN_PLC_START_MAX
   OR stCfg.tDryRelease < GVL_Const.STN_DRY_RELEASE_MIN OR stCfg.tDryRelease > GVL_Const.STN_DRY_RELEASE_MAX
   OR stCfg.tLtRecover > GVL_Const.STN_LT_RECOVER_MAX
   OR stCfg.tLvlConfirm > GVL_Const.STN_LVL_CONFIRM_MAX
   OR stCfg.tV1Overrun > GVL_Const.STN_V1_OVERRUN_MAX THEN
    wErr := wErr OR GVL_Const.STN_CFG_TIMES;
END_IF

// Согласование поплавков и уровнемера
IF NOT (stCfg.rLdev102On_m >= GVL_Const.STN_LDEV102_ON_MIN_M AND stCfg.rLdev102On_m <= GVL_Const.STN_LDEV102_ON_MAX_M
        AND stCfg.rLdev102Off_m >= GVL_Const.STN_LDEV102_OFF_MIN_M
        AND stCfg.rLdev102Off_m <= GVL_Const.STN_LDEV102_OFF_MAX_M
        AND stCfg.rLdev103On_m >= GVL_Const.STN_LDEV103_ON_MIN_M
        AND stCfg.rLdev103On_m <= GVL_Const.STN_LDEV103_ON_MAX_M
        AND stCfg.rLdev103Off_m >= GVL_Const.STN_LDEV103_OFF_MIN_M
        AND stCfg.rLdev103Off_m <= GVL_Const.STN_LDEV103_OFF_MAX_M
        AND stCfg.tLdev >= GVL_Const.STN_LDEV_T_MIN AND stCfg.tLdev <= GVL_Const.STN_LDEV_T_MAX) THEN
    wErr := wErr OR GVL_Const.STN_CFG_FLOAT_CHECK;
END_IF

// Недогрузка по току
IF NOT (stCfg.rUnderload_A >= 0.0 AND stCfg.rUnderload_A <= GVL_Const.STN_UNDERLOAD_MAX_A
        AND stCfg.rUnderloadSpeed_pct >= GVL_Const.STN_UNDERLOAD_SPEED_MIN_PCT
        AND stCfg.rUnderloadSpeed_pct <= PL.GVL_Const.PCT_FULL
        AND stCfg.tUnderload >= GVL_Const.STN_UNDERLOAD_T_MIN
        AND stCfg.tUnderload <= GVL_Const.STN_UNDERLOAD_T_MAX) THEN
    wErr := wErr OR GVL_Const.STN_CFG_UNDERLOAD;
END_IF

// Тревоги: приоритет в перечислении None…Critical (значение в памяти persistent может быть любым)
FOR uiSlot := 1 TO GVL_Const.STN_ALARM_COUNT DO
    iPrio := TO_INT(stCfg.astAlarm[uiSlot].ePriority);
    IF iPrio < TO_INT(PL.E_AlarmPriority.None) OR iPrio > TO_INT(PL.E_AlarmPriority.Critical) THEN
        wErr := wErr OR GVL_Const.STN_CFG_ALARM;
    END_IF
END_FOR

F_StationCfgCheck := wErr;
