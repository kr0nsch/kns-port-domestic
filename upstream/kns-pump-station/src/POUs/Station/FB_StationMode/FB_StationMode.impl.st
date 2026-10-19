// 1. Санитизация энергонезависимых значений — сравнениями, без арифметики (L4 контракта):
//    0 после очистки или мусор в Persistent Variables — «Ручной» и «Ступенчатое», с записью обратно
IF stRetain.eMode <> E_StationMode.Auto AND stRetain.eMode <> E_StationMode.Manual THEN
    stRetain.eMode := E_StationMode.Manual;
END_IF
IF stRetain.eMethod <> E_ControlMethod.Stepped AND stRetain.eMethod <> E_ControlMethod.LevelPid THEN
    stRetain.eMethod := E_ControlMethod.Stepped;
END_IF

xEnteredAuto := FALSE;
xEnteredManual := FALSE;
xMethodChanged := FALSE;
uiCmdCount := 0;

// 2. Режим: каждый импульс — обработанная команда; xSetManual старше xSetAuto (безопасный вариант)
eModeNew := stRetain.eMode;
IF xSetManual THEN
    eModeNew := E_StationMode.Manual;
    uiCmdCount := uiCmdCount + 1;
END_IF
IF xSetAuto THEN
    IF NOT xSetManual THEN
        eModeNew := E_StationMode.Auto;
    END_IF
    uiCmdCount := uiCmdCount + 1;
END_IF

IF eModeNew <> stRetain.eMode THEN
    // Переход: запрос режима насосам. Устройство выполнит его в своём вызове (R3 контракта), поэтому
    // PRG_Station в этом же цикле принимает работающие насосы (xEnteredAuto → FB_PumpRotation.xAdopt).
    // У насоса в Local меняется запомненный дистанционный режим (API 2.2); OutOfService не трогается
    stRetain.eMode := eModeNew;
    FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
        IF aitfPump[uiPump] <> 0 THEN
            ePumpMode := aitfPump[uiPump].Mode;
            IF eModeNew = E_StationMode.Auto THEN
                IF ePumpMode = PL.E_DeviceMode.Manual OR ePumpMode = PL.E_DeviceMode.Local THEN
                    aitfPump[uiPump].RequestMode(eNewMode := PL.E_DeviceMode.Auto);
                END_IF
            ELSIF ePumpMode = PL.E_DeviceMode.Auto OR ePumpMode = PL.E_DeviceMode.Local THEN
                aitfPump[uiPump].RequestMode(eNewMode := PL.E_DeviceMode.Manual);
            END_IF
        END_IF
    END_FOR
    xEnteredAuto := eModeNew = E_StationMode.Auto;
    xEnteredManual := eModeNew = E_StationMode.Manual;
    IF itfEvents <> 0 THEN
        IF xEnteredAuto THEN
            itfEvents.LogEvent(eEvent := E_StationEvent.StationAuto, rValue := 0.0);
        ELSE
            itfEvents.LogEvent(eEvent := E_StationEvent.StationManual, rValue := 0.0);
        END_IF
    END_IF
ELSIF xFirstCall THEN
    // Старт ПЛК: режим из retain; импульс входа без запросов насосам и без события (событие старта —
    // 101015 в PRG_Station): в «Автомате» работающие насосы подхватываются без рывка (04 §13.3)
    xEnteredAuto := eModeNew = E_StationMode.Auto;
    xEnteredManual := eModeNew = E_StationMode.Manual;
END_IF

// 3. Способ регулирования: xSetStepped старше xSetLevelPid; не зависит от режима станции (04 §3.2)
eMethodNew := stRetain.eMethod;
IF xSetStepped THEN
    eMethodNew := E_ControlMethod.Stepped;
    uiCmdCount := uiCmdCount + 1;
END_IF
IF xSetLevelPid THEN
    IF NOT xSetStepped THEN
        eMethodNew := E_ControlMethod.LevelPid;
    END_IF
    uiCmdCount := uiCmdCount + 1;
END_IF
IF eMethodNew <> stRetain.eMethod THEN
    stRetain.eMethod := eMethodNew;
    xMethodChanged := TRUE;
    IF itfEvents <> 0 THEN
        IF eMethodNew = E_ControlMethod.Stepped THEN
            itfEvents.LogEvent(eEvent := E_StationEvent.MethodStepped, rValue := 0.0);
        ELSE
            itfEvents.LogEvent(eEvent := E_StationEvent.MethodLevelPid, rValue := 0.0);
        END_IF
    END_IF
END_IF

// 4. Результат: все команды режима и способа принимаются (команда того же режима — без действий)
IF uiCmdCount > 0 THEN
    eCmdResult := PL.E_CmdResult.Accepted;
END_IF
eMode := stRetain.eMode;
eMethod := stRetain.eMethod;
xFirstCall := FALSE;
