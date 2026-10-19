// Положение по концевикам (с учётом «подключён»): только ZSO — Open, только ZSC — Closed, оба —
// Unknown; ни одного — Intermediate, а без концевиков — Unknown. Старт ПЛК и снятие отказа.
// Внутренний шаг устройства: PROTECTED (правило L5 контракта), имя зарезервировано для наследников
METHOD PROTECTED LimitPosition : E_ValveState
VAR
    xOpenLs  : BOOL;   // ZSO подключён и сработал
    xCloseLs : BOOL;   // ZSC подключён и сработал
END_VAR
