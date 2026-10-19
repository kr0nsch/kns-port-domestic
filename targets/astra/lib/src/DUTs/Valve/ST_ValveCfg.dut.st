// Назначение: параметры запорной арматуры (Persistent Variables приложения,
//             VAR_IN_OUT CONSTANT stCfg). Значения по умолчанию проходят CheckConfig.
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
{attribute 'qualified_only'}
TYPE ST_ValveCfg :
STRUCT
    eType            : E_ValveType := E_ValveType.Motorized;
    xZsoUsed         : BOOL := TRUE;      // концевик «открыто» подключён
    xZscUsed         : BOOL := TRUE;      // концевик «закрыто» подключён
    tTravel          : TIME := T#60S;     // макс. время хода (паспорт привода + запас); без концевика — «по времени»
    tLimitFilter     : TIME := T#500MS;   // фильтр «оба концевика» и ухода с концевика
    tReverse         : TIME := T#1S;      // пауза перед реверсом (Motorized)
    xTorqueUsed      : BOOL := FALSE;     // муфта подключена (Motorized)
    xCloseOnTorque   : BOOL := FALSE;     // закрытие «по моменту» (клиновые задвижки)
    eSafePos         : E_ValveSafePos := E_ValveSafePos.Closed;   // куда вести по блокировке
    wInterlockMask   : WORD := 16#FFFF;   // какие биты wInterlock действуют
    wPermitOpenMask  : WORD := 16#FFFF;   // какие биты wPermitOpen обязательны для открытия
    wPermitCloseMask : WORD := 16#FFFF;   // какие биты wPermitClose обязательны для закрытия
    tResetWindow     : TIME := T#3S;      // окно снятия причин после Reset
    udiMaintCycles   : UDINT := 0;        // ТО по числу циклов; 0 — нет
    udiAlarmIdBase   : UDINT := 0;        // номер первой тревоги устройства (dev_no * 10)
    astAlarm         : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg := [
        (ePriority := E_AlarmPriority.Medium),    // 0 FailToOpen
        (ePriority := E_AlarmPriority.Medium),    // 1 FailToClose
        (ePriority := E_AlarmPriority.Medium),    // 2 BothLimits
        (ePriority := E_AlarmPriority.Medium),    // 3 PositionLost
        (ePriority := E_AlarmPriority.Medium),    // 4 TorqueTrip
        (ePriority := E_AlarmPriority.Medium),    // 5 ExtFault
        (ePriority := E_AlarmPriority.None),      // 6 InterlockAct
        (ePriority := E_AlarmPriority.None)];     // 7 —
END_STRUCT
END_TYPE
