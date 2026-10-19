// Назначение: часы контура (FB_ScaledClock): MainTask — устройства, станция, журнал; PlantModelTask —
//             модель. Оба экземпляра ускоряются общим коэффициентом GVL_Sim.stSimCfg.rTimeScale и
//             перебазируются при его смене в начале цикла своей задачи.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 4.4, 10; docs/ARCHITECTURE.md, раздел 11
{attribute 'qualified_only'}
VAR_GLOBAL
    fbClockMain  : FB_ScaledClock;      // MainTask: устройства (time_source iolistgen), станция, журнал
    fbClockModel : FB_ScaledClock;      // PlantModelTask
    lrMainNow_s  : LREAL;               // время процесса MainTask, с (Read): пишет PRG_FieldIn после Update
END_VAR
