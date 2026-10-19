// Назначение: параметры двигателя (FB_Motor и FB_MotorVfd; Persistent Variables приложения,
//             VAR_IN_OUT CONSTANT stCfg). Значения по умолчанию проходят CheckConfig. Маски
//             по умолчанию 16#FFFF: забытая маска даёт «блокирует», а не «молча игнорирует».
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Motor.md
{attribute 'qualified_only'}
TYPE ST_MotorCfg :
STRUCT
    xFbUsed            : BOOL := TRUE;      // ОС «в работе» подключена
    tFbStart           : TIME := T#5S;      // ожидание ОС при пуске (для УПП — не меньше времени разгона)
    tFbStop            : TIME := T#5S;      // ожидание пропадания ОС при останове (выбег)
    tFbLossFilter      : TIME := T#500MS;   // фильтр пропадания ОС в работе
    tExtFaultFilter    : TIME := T#200MS;   // фильтр внешней аварии
    tMinRun            : TIME := T#0S;      // мин. время работы — только для остановов от автоматики
    tMinStop           : TIME := T#0S;      // мин. пауза перед пуском (также после старта ПЛК и провала питания)
    uiMaxStartsPerHour : UINT := 0;         // 0 — без ограничения; не больше STARTS_WINDOW_MAX
    tResetWindow       : TIME := T#3S;      // окно снятия причин после Reset (сброс УПП/ПЧ)
    tResetPulse        : TIME := T#1S;      // длительность импульса xQReset; не больше tResetWindow
    wInterlockMask     : WORD := 16#FFFF;   // какие биты wInterlock действуют
    wPermitMask        : WORD := 16#FFFF;   // какие биты wPermit обязательны для пуска
    udiMaintInterval_h : UDINT := 0;        // ТО по наработке, ч; 0 — нет
    udiMaintStarts     : UDINT := 0;        // ТО по числу пусков; 0 — нет
    stVfd              : ST_VfdCfg;         // только FB_MotorVfd
    udiAlarmIdBase     : UDINT := 0;        // номер первой тревоги устройства (dev_no * 10)
    astAlarm           : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg := [
        (ePriority := E_AlarmPriority.Medium),    // 0 FailToStart
        (ePriority := E_AlarmPriority.Medium),    // 1 FeedbackLost
        (ePriority := E_AlarmPriority.High),      // 2 FailToStop — механизм не остановить из ПЛК
        (ePriority := E_AlarmPriority.High),      // 3 UncommandedRun
        (ePriority := E_AlarmPriority.Medium),    // 4 ExtFault
        (ePriority := E_AlarmPriority.None),      // 5 InterlockTrip — у причины обычно своя тревога
        (ePriority := E_AlarmPriority.Medium),    // 6 CommLoss (ПЧ)
        (ePriority := E_AlarmPriority.Low)];      // 7 SpeedDeviation (ПЧ)
END_STRUCT
END_TYPE
