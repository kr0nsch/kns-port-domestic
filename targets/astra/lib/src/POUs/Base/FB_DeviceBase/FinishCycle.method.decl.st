// Шаг 8 цикла: сводный NE 107 = MAX(статус устройства, статус режима, статус Cfg), Fault, Available,
// общий заголовок stCommon (все 14 полей, старший байт wStatus — общие биты DEV_STS_*), затем
// ltPrevCall := ltNow, конец первого вызова и снятие запросов методов
METHOD PROTECTED FinishCycle
VAR_INPUT
    eDevStatus    : E_Ne107Status;   // статус от логики устройства (Failure, OutOfSpecification, MaintenanceRequired)
    xAvailableDev : BOOL;            // готовность по логике устройства
    wLow          : WORD;            // биты устройства (младший байт wStatus)
    wFaultBits    : WORD;            // wFault
    wWarnBits     : WORD;            // wWarning
END_VAR
VAR_IN_OUT
    stCommon : ST_DeviceSts;         // stSts.stCommon устройства
END_VAR
VAR
    xCfgBad     : BOOL;                                          // нет корректной Cfg или она испорчена
    eModeStatus : E_Ne107Status := E_Ne107Status.Good;           // вклад режима
    eCfgStatus  : E_Ne107Status := E_Ne107Status.Good;           // вклад конфигурации
    wHigh       : WORD;                                          // общие биты 8–15 wStatus
END_VAR
