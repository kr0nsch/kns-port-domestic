// Назначение: команды модели (GVL_Sim.stSimCmd). Импульсы сбрасывает модель (FB_PlantModel)
//             после выполнения; xInflowOverride и xDoorOpen — уровни.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.3; docs/06_PMI.md, раздел 5.4
{attribute 'qualified_only'}
TYPE ST_SimCmd :
STRUCT
    xResetPlant      : BOOL;        // импульс: уровень := stSimCfg.rLevelInit_m, перелив 0, ливни сняты, ПЧ готовы
    xClearFaults     : BOOL;        // импульс: обнулить stFaultInj (ускорение и приток не меняются)
    xSetLevel        : BOOL;        // импульс: уровень := rSetLevel_m
    rSetLevel_m      : REAL;
    xInflowOverride  : BOOL;        // уровень: приток := rInflowOverride_m3h (без профиля и ливней)
    rInflowOverride_m3h : REAL;
    xStormNow        : BOOL;        // импульс: ливень сейчас (при xInflowOverride = FALSE)
    rStormPeak_m3h   : REAL;
    tStormDuration   : TIME;
    xSetTimeOfDay    : BOOL;        // импульс: время суток модели := rTimeOfDay_h
    rTimeOfDay_h     : REAL;
    xPressReset      : BOOL;        // импульс: нажать HS501 на SIM_BUTTON_PULSE
    xPressSilence    : BOOL;        // импульс: нажать HS502
    xDoorOpen        : BOOL;        // уровень: дверь павильона открыта (ZS404)
END_STRUCT
END_TYPE
