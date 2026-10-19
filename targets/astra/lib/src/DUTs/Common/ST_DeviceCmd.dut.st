// Назначение: общий заголовок команд HMI/SCADA — первое поле stCommon каждой ST_<Dev>Cmd.
//             Импульсные биты ФБ сбрасывает в том же вызове, маски обнуляет после обработки.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Общие типы»
{attribute 'qualified_only'}
TYPE ST_DeviceCmd :
STRUCT
    xSetAuto     : BOOL;   // импульс: в Auto (AI/DI: измерение; выход из OOS)
    xSetManual   : BOOL;   // импульс: в Manual (AI/DI: подмена; выход из OOS)
    xSetOos      : BOOL;   // импульс: вывести из работы
    xReset       : BOOL;   // импульс: сброс зафиксированных отказов + квитирование всех тревог
    xAck         : BOOL;   // импульс: квитировать все тревоги (без сброса отказов)
    wAckReq      : WORD;   // маска: квитировать тревоги слотов (бит i = слот i)
    wShelveReq   : WORD;   // маска: отложить тревоги слотов на stCfg.astAlarm[i].tShelveMax
    wUnshelveReq : WORD;   // маска: вернуть отложенные тревоги
END_STRUCT
END_TYPE
