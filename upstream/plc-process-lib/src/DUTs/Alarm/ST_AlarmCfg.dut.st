// Назначение: параметры одной тревоги (слот astAlarm[i] в Cfg устройства). 16 байт.
//             Тип лежит в Persistent Variables приложения и заморожен в пределах 1.x (A-13).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Тревоги»
{attribute 'qualified_only'}
TYPE ST_AlarmCfg :
STRUCT
    ePriority  : E_AlarmPriority := E_AlarmPriority.Medium;
    tOnDelay   : TIME := T#0S;   // задержка появления
    tOffDelay  : TIME := T#0S;   // задержка снятия
    tShelveMax : TIME := T#8H;   // максимальный срок shelve; T#0S — откладывать запрещено
END_STRUCT
END_TYPE
