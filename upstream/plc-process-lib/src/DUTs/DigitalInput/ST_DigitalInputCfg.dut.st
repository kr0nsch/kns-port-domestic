// Назначение: параметры дискретного входа (Persistent Variables приложения,
//             VAR_IN_OUT CONSTANT stCfg). Значения по умолчанию проходят CheckConfig.
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_DigitalInput.md
{attribute 'qualified_only'}
TYPE ST_DigitalInputCfg :
STRUCT
    xInvert        : BOOL := FALSE;    // инверсия до задержек (НЗ-контакт)
    tOnDelay       : TIME := T#0S;     // задержка включения
    tOffDelay      : TIME := T#0S;     // задержка отключения
    eFailValue     : E_DiFailValue := E_DiFailValue.HoldLast;
    xAlarmOnTrue   : BOOL := TRUE;     // тревога State при xValue = TRUE (FALSE — при xValue = FALSE)
    tSubstMax      : TIME := T#8H;     // макс. длительность подмены; T#0S — без ограничения
    udiAlarmIdBase : UDINT := 0;       // номер первой тревоги устройства (dev_no * 10)
    astAlarm       : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg := [
        (ePriority := E_AlarmPriority.None),      // 0 State — включает генератор, если сигнал тревожный
        (ePriority := E_AlarmPriority.Medium),    // 1 Failure
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None),
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None),
        (ePriority := E_AlarmPriority.None), (ePriority := E_AlarmPriority.None)];
END_STRUCT
END_TYPE
