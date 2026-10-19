// Назначение: команды HMI/SCADA запорной арматуры (GVL_Hmi приложения, VAR_IN_OUT stCmd).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
{attribute 'qualified_only'}
TYPE ST_ValveCmd :
STRUCT
    stCommon    : ST_DeviceCmd;
    xOpen       : BOOL;   // импульс: открыть (в Auto — переход в Manual и открыть)
    xClose      : BOOL;   // импульс: закрыть (в Auto — переход в Manual и закрыть)
    xStop       : BOOL;   // импульс: стоп (только Motorized; в Auto — переход в Manual)
    xResetMaint : BOOL;   // импульс: обнулить счётчики «с последнего ТО»
END_STRUCT
END_TYPE
