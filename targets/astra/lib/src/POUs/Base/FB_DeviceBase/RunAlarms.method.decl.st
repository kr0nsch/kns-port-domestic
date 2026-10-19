// Шаг 7 цикла: запросы тревог (квитировать всё, маски квитирования, shelve и unshelve), вызов
// используемых слотов и сводка wAlmActive, wAlmUnack, wAlmShelved, wAlmSuppressed, ePrioUnack. Сбрасывает xAck,
// xReset и маски stCmd. Циклы — FOR uiLoop := 1 TO MIN(uiAlarmCount, DEV_ALARMS_MAX): при 0 слотов
// беззнаковое «uiAlarmCount - 1» не возникает
METHOD PROTECTED RunAlarms
VAR_INPUT
    udiIdBase : UDINT;            // номер первой тревоги устройства (stCfgLkg.udiAlarmIdBase)
END_VAR
VAR_IN_OUT
    stCmd : ST_DeviceCmd;         // общий заголовок команд
END_VAR
VAR_IN_OUT CONSTANT
    astCfg : ARRAY[0..GVL_Const.DEV_ALARMS_MAX - 1] OF ST_AlarmCfg;   // stCfgLkg.astAlarm
END_VAR
VAR
    uiUsed     : UINT;            // слотов в работе: MIN(uiAlarmCount, DEV_ALARMS_MAX)
    uiLoop     : UINT;            // номер слота + 1
    uiSlot     : UINT;            // номер слота
    wBit       : WORD;            // бит слота в масках
    xAckAllNow : BOOL;            // квитировать все слоты
    xShelveAny : BOOL;            // хотя бы один слот принял shelve
    xAccepted  : BOOL;            // ответ метода слота (запрос выполнит вызов слота ниже)
    eSlotState : E_AlarmState := E_AlarmState.Normal;   // состояние слота
END_VAR
