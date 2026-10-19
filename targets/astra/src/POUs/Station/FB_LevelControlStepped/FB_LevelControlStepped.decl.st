// Назначение: ступенчатое регулирование по уровням пуска и останова с гистерезисом (04 §6):
//             автомат 0/1/2 насоса, каждое пересечение подтверждается выдержкой tLvlConfirm
//             (границы включительно: пуск при уровне >=, останов при <=). Недостоверный уровень —
//             состояние держится. При xEnable = FALSE выход 0, автомат работает дальше (таймеры
//             непрерывны), состояние задаёт следующий xInit (вход без рывка по числу работающих).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.3; docs/04_algorithms.md, раздел 6
FUNCTION_BLOCK FB_LevelControlStepped
VAR_INPUT
    xEnable     : BOOL;             // eControlAct = Stepped
    rLevel_m    : REAL;             // fbLT101.rValue_eu
    xLevelValid : BOOL;             // fbLT101.xValid
    xInit       : BOOL;             // импульс: число насосов := uiInitPumps (вход без рывка)
    uiInitPumps : UINT;             // работающие насосы станции
    itfTime     : PL.I_TimeSource;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // rLvl*_m, tLvlConfirm, rStepSpeed_pct, uiDutyMax
END_VAR
VAR_OUTPUT
    uiRequired  : UINT;             // 0…MIN(2, uiDutyMax)
    rSpeed_pct  : REAL;             // stCfg.rStepSpeed_pct
    xConfirming : BOOL;             // идёт выдержка tLvlConfirm
END_VAR
VAR
    uiPumps        : UINT;          // состояние автомата: 0, 1, 2 насоса
    fbStartLead    : PL.FB_Delay;   // 0 → 1: уровень >= rLvlStartLead_m
    fbStartAssist  : PL.FB_Delay;   // 1 → 2: уровень >= rLvlStartAssist_m
    fbStopAssist   : PL.FB_Delay;   // 2 → 1: уровень <= rLvlStopAssist_m
    fbStopAll      : PL.FB_Delay;   // 1, 2 → 0: уровень <= rLvlStop_m
END_VAR
VAR_TEMP
    uiMax : UINT;                   // предел числа насосов: MIN(STN_DUTY_MAX, uiDutyMax)
END_VAR
