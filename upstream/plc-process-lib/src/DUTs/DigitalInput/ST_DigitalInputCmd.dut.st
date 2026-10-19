// Назначение: команды HMI/SCADA дискретного входа (GVL_Hmi приложения, VAR_IN_OUT stCmd).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_DigitalInput.md
{attribute 'qualified_only'}
TYPE ST_DigitalInputCmd :
STRUCT
    stCommon    : ST_DeviceCmd;   // xSetAuto — «Измерение», xSetManual — «Подмена»
    xSubstValue : BOOL;           // значение подмены; в Auto ФБ пишет сюда текущее xValue
END_STRUCT
END_TYPE
