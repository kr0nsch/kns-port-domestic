// Назначение: параметры аналогового входа (Persistent Variables приложения,
//             VAR_IN_OUT CONSTANT stCfg). Значения по умолчанию проходят CheckConfig.
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_AnalogInput.md
{attribute 'qualified_only'}
TYPE ST_AnalogInputCfg :
STRUCT
    eInput         : E_AiInputType := E_AiInputType.MilliAmp;
    rRangeLo_eu    : REAL := 0.0;      // значение при 4 мА / 0.0
    rRangeHi_eu    : REAL := 100.0;    // значение при 20 мА / 1.0 / rRawHi_cnt
    rRawLo_cnt     : REAL := 0.0;      // только Raw: значение канала, соответствующее rRangeLo_eu
    rRawHi_cnt     : REAL := 0.0;      // только Raw: значение канала, соответствующее rRangeHi_eu (0/0 — не задано)
    xSqrt          : BOOL := FALSE;    // корень (расход по перепаду давления)
    rLowCut_pct    : REAL := 0.0;      // отсечка малых значений, % шкалы (после корня); 0 — нет
    tFilter        : TIME := T#0S;     // постоянная времени фильтра; T#0S — без фильтра
    tFailDelay     : TIME := T#2S;     // подтверждение отказа / выхода за диапазон и возврата
    eFailValue     : E_AiFailValue := E_AiFailValue.HoldLast;
    rFailValue_eu  : REAL := 0.0;      // значение при Substitute
    xLimitsOnFail  : BOOL := FALSE;    // TRUE — при подтверждённом отказе уставки считаются по значению отказа
    xClamp         : BOOL := FALSE;    // ограничить значение шкалой (по умолчанию — экстраполяция)
    astLimit       : ARRAY[0..3] OF ST_AiLimitCfg;   // индекс E_AiAlarm.HH, H, L, LL
    tSubstMax      : TIME := T#8H;     // макс. длительность подмены; T#0S — без ограничения
    udiAlarmIdBase : UDINT := 0;       // номер первой тревоги устройства (dev_no * 10)
    astAlarm       : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg := [
        (ePriority := E_AlarmPriority.High),      // 0 HH
        (ePriority := E_AlarmPriority.Low),       // 1 H
        (ePriority := E_AlarmPriority.Low),       // 2 L
        (ePriority := E_AlarmPriority.High),      // 3 LL
        (ePriority := E_AlarmPriority.Medium),    // 4 Failure
        (ePriority := E_AlarmPriority.Low),       // 5 OutOfRange
        (ePriority := E_AlarmPriority.None),      // 6 —
        (ePriority := E_AlarmPriority.None)];     // 7 —
END_STRUCT
END_TYPE
