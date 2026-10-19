// 6.3 Внешняя авария: во всех режимах, кроме OutOfService; фиксируется
IF xExtFault AND eMode <> E_DeviceMode.OutOfService THEN
    xFltExt := TRUE;
END_IF

// 6.4 Концевики (контроль — в Auto/Manual при корректной Cfg; в Local и OOS арматуру двигают руками).
//     «Оба концевика» дольше tLimitFilter — нефиксируемый отказ; при старте ПЛК — сразу
xSupervise := xRemote AND xCfgEverOk;
fbBoth(xIn := xSupervise AND xAtOpen AND xAtClose, tOnDelay := stCfgLkg.tLimitFilter, itfTime := itfTimeAct);
IF xFirstCall THEN
    fbBoth.Preset(xValue := xSupervise AND xAtOpen AND xAtClose);
END_IF
xBothLimits := fbBoth.xOut;
//     уход с концевика: в Open/Closed, подтверждённом концевиком, он пропал без команды дольше
//     tLimitFilter — фиксируемый отказ; без напряжения не контролируется (соленоид уходит на пружину)
xPosSup := xSupervise AND xPowerOk;
xLeftEnd := xEndByLs AND ((eState = E_ValveState.Open AND NOT xAtOpen)
                          OR (eState = E_ValveState.Closed AND NOT xAtClose));
fbPosLost(xIn := xPosSup AND xLeftEnd, tOnDelay := stCfgLkg.tLimitFilter, itfTime := itfTimeAct);
IF fbPosLost.xOut THEN
    xFltPosLost := TRUE;
END_IF
