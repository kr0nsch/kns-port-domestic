// Назначение: команды HMI/SCADA аналогового входа (GVL_Hmi приложения, VAR_IN_OUT stCmd).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_AnalogInput.md
{attribute 'qualified_only'}
TYPE ST_AnalogInputCmd :
STRUCT
    stCommon       : ST_DeviceCmd;   // xSetAuto — «Измерение», xSetManual — «Подмена», xSetOos
    rSubstValue_eu : REAL;           // значение подмены; в Auto ФБ пишет сюда текущее rValue_eu
END_STRUCT
END_TYPE
