// Проверка конфигурации тревог для CheckConfig устройства: TRUE, если приоритеты всех слотов —
// значения перечисления E_AlarmPriority (0…4)
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED CheckAlarmCfg : BOOL
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    astCfg : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg;   // stCfgIn.astAlarm устройства
END_VAR
VAR
    uiLoop : UINT;                                        // номер слота + 1
    ePrio  : E_AlarmPriority := E_AlarmPriority.Medium;   // приоритет слота
    xOk    : BOOL := TRUE;                                // все проверенные слоты корректны
END_VAR
