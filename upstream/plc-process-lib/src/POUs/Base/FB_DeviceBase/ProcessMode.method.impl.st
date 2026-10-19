// 1. Санитизация: значение вне {Auto, Manual} (0 после очистки, мусор persistent-памяти) — Manual.
//    Строгое перечисление защищает только исходный текст, поэтому проверка — сравнениями
IF stRetain.eRemoteMode <> E_DeviceMode.Auto AND stRetain.eRemoteMode <> E_DeviceMode.Manual THEN
    stRetain.eRemoteMode := E_DeviceMode.Manual;
END_IF

// 2. Победивший запрос: биты stCmd и RequestMode() вместе, по старшинству OutOfService > Manual > Auto
xAnyReq := TRUE;
IF stCmd.xSetOos OR (xModeReq AND eModeReq = E_DeviceMode.OutOfService) THEN
    eWinner := E_DeviceMode.OutOfService;
ELSIF stCmd.xSetManual OR (xModeReq AND eModeReq = E_DeviceMode.Manual) THEN
    eWinner := E_DeviceMode.Manual;
ELSIF stCmd.xSetAuto OR (xModeReq AND eModeReq = E_DeviceMode.Auto) THEN
    eWinner := E_DeviceMode.Auto;
ELSE
    xAnyReq := FALSE;
END_IF
stCmd.xSetAuto := FALSE;
stCmd.xSetManual := FALSE;
stCmd.xSetOos := FALSE;
xModeReq := FALSE;

// 3. Выполнение: OutOfService — только при стоящем механизме (повтор в OutOfService принимается);
//    Auto и Manual запоминаются в stRetain (в Local тоже) и выводят из OutOfService
IF xAnyReq THEN
    IF eWinner = E_DeviceMode.OutOfService THEN
        IF xOosAllowed OR stRetain.xOutOfService THEN
            stRetain.xOutOfService := TRUE;
            eResult := E_CmdResult.Accepted;
        ELSE
            eResult := E_CmdResult.RejectedState;
        END_IF
    ELSE
        stRetain.eRemoteMode := eWinner;
        stRetain.xOutOfService := FALSE;
        eResult := E_CmdResult.Accepted;
    END_IF
END_IF
ProcessMode := eResult;

// 4. Режим по старшинству OutOfService > Local > дистанционный
IF stRetain.xOutOfService THEN
    eModeNew := E_DeviceMode.OutOfService;
ELSIF xLocalSel AND xLocalSupported THEN
    eModeNew := E_DeviceMode.Local;
ELSE
    eModeNew := stRetain.eRemoteMode;
END_IF
IF eModeNew <> eMode THEN
    eModeOld := eMode;
    eMode := eModeNew;
    THIS^.OnModeChanged(eOld := eModeOld, eNew := eModeNew);
END_IF
