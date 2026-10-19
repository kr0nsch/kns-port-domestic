// Шаг 3: Reset. Результат Accepted сразу; в окне tResetWindow зафиксированные отказы снимаются, как
// только ушла их причина (ход и положение — сразу: привод стоит); если к концу окна отказ остался —
// второй результат RejectedFault. Первопричина блокировки снимается.
// Шаг тела FB_Valve; внутренний: PROTECTED (правило L5 контракта), имя зарезервировано для наследников
METHOD PROTECTED ResetFaults
VAR_INPUT
    xRequest : BOOL;   // Reset() или stCmd.stCommon.xReset в этом вызове
END_VAR
