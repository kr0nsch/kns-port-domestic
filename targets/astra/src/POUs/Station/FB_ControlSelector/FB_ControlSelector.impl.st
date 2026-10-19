// Режим вне перечисления (мусор) — как «Ручной», способ вне перечисления — как «Ступенчатое»
// (E_StationMode, E_ControlMethod: безопасный вариант)
IF eMode <> E_StationMode.Auto THEN
    eControlAct := E_ControlAct.Manual;
ELSIF xPowerLost THEN
    eControlAct := E_ControlAct.PowerLost;
ELSIF xRestart THEN
    eControlAct := E_ControlAct.Restart;
ELSIF xDryRun THEN
    eControlAct := E_ControlAct.DryRunStop;
ELSIF xFloatMode THEN
    eControlAct := E_ControlAct.Float;
ELSIF xEmergency THEN
    eControlAct := E_ControlAct.Emergency;
ELSIF eMethod = E_ControlMethod.LevelPid AND xPidReady THEN
    eControlAct := E_ControlAct.LevelPid;
ELSE
    eControlAct := E_ControlAct.Stepped;
END_IF

// Условие KNS1.STEP не зависит от старших состояний: их подавление задаёт PRG_Station (04 §15)
xStepFallback := eMode = E_StationMode.Auto AND eMethod = E_ControlMethod.LevelPid AND NOT xPidReady;

xChanged := eControlAct <> eActPrev;
eActPrev := eControlAct;
