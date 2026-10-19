// Назначение: проверка уставок станции (04 §18.3): порядок отметок 04 §1 (LS103 < L < останов <
//             останов подпорного < пуск ведущего < пуск подпорного < H < LS102), диапазоны и
//             зазоры 04 §18.2, rAssistOff_pct <= rAssistOn_pct - 10, приоритеты тревог в
//             перечислении, задание уровня в пределах задания LIC101. Неконечное значение (NaN,
//             ±Inf) не проходит ни одну проверку своей группы. Результат — биты STN_CFG_*;
//             0 — уставки корректны (принимаются как последняя корректная копия).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.13; docs/04_algorithms.md, раздел 18
FUNCTION F_StationCfgCheck : WORD   // биты STN_CFG_*; 0 — уставки корректны
VAR_IN_OUT CONSTANT
    stCfg    : ST_StationCfg;
    stPidCfg : PL.ST_PidCfg;        // rSpMin_eu, rSpMax_eu — пределы задания
END_VAR
VAR_INPUT
    rLvlL_m  : REAL;                // GVL_Persist.stLT101Cfg.astLimit[L].rSetpoint_eu
    rLvlH_m  : REAL;                // … [H]
END_VAR
VAR
    wErr   : WORD;                  // накопленные биты
    uiSlot : UINT;                  // слот тревоги
    iPrio  : INT;                   // приоритет тревоги числом (значение в памяти может быть любым)
END_VAR
