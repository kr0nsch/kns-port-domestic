// Назначение: параметры регулирующего клапана (Persistent Variables приложения,
//             VAR_IN_OUT CONSTANT stCfg). Значения по умолчанию проходят CheckConfig.
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_ControlValve.md
{attribute 'qualified_only'}
TYPE ST_ControlValveCfg :
STRUCT
    rOutMin_pct     : REAL := 0.0;     // нижний предел задания, %
    rOutMax_pct     : REAL := 100.0;   // верхний предел задания, %
    rRateUp_pctps   : REAL := 0.0;     // %/с; 0 — без ограничения
    rRateDown_pctps : REAL := 0.0;     // %/с; 0 — без ограничения
    rTightShut_pct  : REAL := 0.0;     // выход ниже порога → 0 % (плотное закрытие); 0 — выключено
    xOutInvert      : BOOL := FALSE;   // TRUE: 100 % хода = 4 мА
    rSafePos_pct    : REAL := 0.0;     // положение по блокировке и отказу (не путать с механическим)
    eFaultAction    : E_CvFaultAction := E_CvFaultAction.Hold;
    xFbUsed         : BOOL := FALSE;   // ОС положения подключена
    rDevMax_pct     : REAL := 5.0;     // допуск рассогласования, %
    tDev            : TIME := T#30S;   // задержка рассогласования
    xDevIsFault     : BOOL := FALSE;   // FALSE — рассогласование только предупреждение
    wInterlockMask  : WORD := 16#FFFF; // какие биты wInterlock действуют
    udiAlarmIdBase  : UDINT := 0;      // номер первой тревоги устройства (dev_no * 10)
    astAlarm        : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg := [
        (ePriority := E_AlarmPriority.Low),       // 0 Deviation
        (ePriority := E_AlarmPriority.Low),       // 1 FbFailure
        (ePriority := E_AlarmPriority.Medium),    // 2 PositionerFault
        (ePriority := E_AlarmPriority.None),      // 3 InterlockAct
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None),
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None)];
END_STRUCT
END_TYPE
