// Назначение: команды HMI/SCADA регулирующего клапана (GVL_Hmi приложения, VAR_IN_OUT stCmd).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_ControlValve.md
{attribute 'qualified_only'}
TYPE ST_ControlValveCmd :
STRUCT
    stCommon      : ST_DeviceCmd;
    rPosSpMan_pct : REAL;   // задание в Manual, %; в Auto/Local/OOS ФБ пишет сюда текущий rOut_pct
END_STRUCT
END_TYPE
