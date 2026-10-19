// Назначение: результат обработки команды HMI/SCADA или запроса метода
//             (stSts.stCommon.eCmdResult; каждая обработанная команда увеличивает uiCmdSeq).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Общие типы»
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_CmdResult :
(
    None                 := 0,   // команд ещё не было
    Accepted             := 1,
    RejectedMode         := 2,   // недопустимо в текущем режиме (пуск в Auto; команды в Local/OOS)
    RejectedInterlock    := 3,   // действует защитная блокировка
    RejectedPermit       := 4,   // нет разрешения (в т. ч. ПЧ не готов)
    RejectedInhibit      := 5,   // пауза после останова, лимит пусков, нет напряжения
    RejectedFault        := 6,   // есть отказ; Reset при неснятой причине; PV негодна (ПИД)
    RejectedState        := 7,   // недопустимо в текущем состоянии (OOS при работающем механизме)
    RejectedNotSupported := 8,   // не поддерживается типом (стоп соленоида, Local у AI)
    RejectedCfg          := 9,   // нет корректной конфигурации
    SubstExpired         := 10   // AI/DI: подмена снята по tSubstMax (событие, а не ответ на команду)
) INT;
END_TYPE
