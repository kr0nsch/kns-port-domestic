// Назначение: команды HMI/SCADA двигателя (FB_Motor и FB_MotorVfd, VAR_IN_OUT stCmd).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Motor.md
{attribute 'qualified_only'}
TYPE ST_MotorCmd :
STRUCT
    stCommon     : ST_DeviceCmd;
    xStart       : BOOL;   // импульс: пуск (Manual; в Auto — RejectedMode)
    xStop        : BOOL;   // импульс: стоп (в Auto — переход в Manual и стоп)
    xResetMaint  : BOOL;   // импульс: обнулить счётчики «с последнего ТО»
    rSpeedSp_pct : REAL;   // ПЧ: задание скорости в Manual, %; в Auto/Local/OOS ФБ пишет сюда текущее
END_STRUCT
END_TYPE
