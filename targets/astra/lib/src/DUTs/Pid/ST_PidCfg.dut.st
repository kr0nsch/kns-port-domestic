// Назначение: параметры ПИД-регулятора (Persistent Variables приложения,
//             VAR_IN_OUT CONSTANT stCfg). Значения по умолчанию проходят CheckConfig.
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_PID.md
{attribute 'qualified_only'}
TYPE ST_PidCfg :
STRUCT
    eAction        : E_PidAction := E_PidAction.Reverse;
    rKp            : REAL := 1.0;     // %/% (выход в % на % диапазона PV); знак — только через eAction
    rTi_s          : REAL := 30.0;    // 0 — без И (интегратор = смещение, задаётся предустановкой)
    rTd_s          : REAL := 0.0;     // 0 — без Д
    rDFilterN      : REAL := 10.0;    // фильтр Д: Tf = Td / N
    rTt_s          : REAL := 0.0;     // постоянная слежения anti-windup; 0 — авто
    rPvMin_eu      : REAL := 0.0;     // диапазон PV для нормировки (как у датчика)
    rPvMax_eu      : REAL := 100.0;
    rSpMin_eu      : REAL := 0.0;     // пределы задания
    rSpMax_eu      : REAL := 100.0;
    rSpRate_ups    : REAL := 0.0;     // рампа задания, инж. ед./с; 0 — нет
    rOutMin_pct    : REAL := 0.0;     // пределы выхода
    rOutMax_pct    : REAL := 100.0;
    rOutRate_pctps : REAL := 0.0;     // ограничение скорости выхода, %/с; 0 — нет
    rDeadband_pct  : REAL := 0.0;     // зона нечувствительности по ошибке, % диапазона PV
    tSample        : TIME := T#0S;    // период расчёта; T#0S — каждый вызов
    tDtMax         : TIME := T#2S;    // больший шаг — разрыв (стоп ПЛК, отладка): шаг пропускается
    ePvFailAction  : E_PidPvFailAction := E_PidPvFailAction.Hold;
    rSafeOut_pct   : REAL := 0.0;     // выход при ePvFailAction = SafeOut
    xSpTrackPv     : BOOL := FALSE;   // в Manual задание следует за PV
    xUseOutAct     : BOOL := FALSE;   // обратный расчёт по rOutAct_pct (внешнее насыщение)
    udiAlarmIdBase : UDINT := 0;      // номер первой тревоги устройства (dev_no * 10)
    astAlarm       : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg := [
        (ePriority := E_AlarmPriority.Medium),    // 0 PvInvalid
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None),
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None),
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None),
        (ePriority := E_AlarmPriority.None)];
END_STRUCT
END_TYPE
