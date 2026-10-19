// Назначение: значение аналогового входа при подтверждённом отказе сигнала.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_AnalogInput.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_AiFailValue :
(
    HoldLast   := 0,   // удерживать последнее хорошее значение
    Substitute := 1    // подставить stCfg.rFailValue_eu
) INT;
END_TYPE
