// Назначение: действующее управление насосами (04 §4). В «Автомате» по старшинству: PowerLost >
//             Restart > DryRunStop > Float > Emergency > LevelPid (выбран и готов) > Stepped; в
//             «Ручном» — Manual. xStepFallback — условие тревоги KNS1.STEP (выбран ПИД, ПИД не
//             готов); xChanged — импульс смены управления (вход без рывка в PRG_Station).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.2; docs/04_algorithms.md, раздел 4
FUNCTION_BLOCK FB_ControlSelector
VAR_INPUT
    eMode      : E_StationMode;
    eMethod    : E_ControlMethod;
    xPowerLost : BOOL;              // FB_PowerRestore
    xRestart   : BOOL;
    xDryRun    : BOOL;              // FB_Protections
    xFloatMode : BOOL;
    xEmergency : BOOL;
    xPidReady  : BOOL;              // FB_LevelControlPid
END_VAR
VAR_OUTPUT
    eControlAct   : E_ControlAct;
    xStepFallback : BOOL;           // Auto, выбран ПИД, ПИД не готов (условие KNS1.STEP)
    xChanged      : BOOL;           // eControlAct сменилось в этом вызове
END_VAR
VAR
    eActPrev : E_ControlAct;        // управление прошлого вызова (первый вызов — Manual)
END_VAR
