// Шаг 4 цикла: автомат режима. Санитизация stRetain.eRemoteMode; победивший запрос среди битов
// stCmd и RequestMode() по старшинству OutOfService > Manual > Auto (одновременные запросы —
// одна команда); сброс импульсов режима; новый режим по старшинству OutOfService > Local >
// дистанционный; при смене — виртуальный хук THIS^.OnModeChanged. Результат None — запросов не было
METHOD PROTECTED ProcessMode : E_CmdResult
VAR_INPUT
    xLocalSel       : BOOL;   // переключатель в положении «Местное»
    xLocalSupported : BOOL;   // у типа есть режим Local
    xOosAllowed     : BOOL;   // механизм стоит: вывод из работы допустим
END_VAR
VAR_IN_OUT
    stCmd    : ST_DeviceCmd;      // общий заголовок команд: импульсы режима сбрасываются
    stRetain : ST_DeviceRetain;   // дистанционный режим и признак OutOfService (AI/DI — stModeMem)
END_VAR
VAR
    xAnyReq   : BOOL;                                    // в этом вызове есть запрос режима
    eWinner   : E_DeviceMode := E_DeviceMode.Manual;     // победивший запрос
    eModeOld  : E_DeviceMode := E_DeviceMode.Manual;     // режим до смены
    eModeNew  : E_DeviceMode := E_DeviceMode.Manual;     // режим по итогам вызова
    eResult   : E_CmdResult := E_CmdResult.None;         // результат запроса режима
END_VAR
