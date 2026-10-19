// Назначение: команды HMI/SCADA ПИД-регулятора (GVL_Hmi приложения, VAR_IN_OUT stCmd).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_PID.md
{attribute 'qualified_only'}
TYPE ST_PidCmd :
STRUCT
    stCommon       : ST_DeviceCmd;   // xSetAuto, xSetManual, xSetOos, xReset, xAck ...
    rSp_eu         : REAL;           // задание оператора; при xSpExt ФБ пишет сюда внешнее
    rManualOut_pct : REAL;           // выход в Manual, %; в Auto/Track/OOS ФБ пишет сюда текущий выход
END_STRUCT
END_TYPE
