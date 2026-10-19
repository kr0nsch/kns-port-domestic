//     пауза реверса: отсчёт с входа в Reversing, затем направление по цели
fbReverse(xIn := eState = E_ValveState.Reversing, tOnDelay := stCfgLkg.tReverse, itfTime := itfTimeAct);
IF eState = E_ValveState.Reversing AND fbReverse.xOut THEN
    IF eTarget = E_ValveState.Open AND xMayOpen THEN
        eState := E_ValveState.Opening;
        xEnterMove := TRUE;
    ELSIF eTarget = E_ValveState.Closed AND xMayClose THEN
        eState := E_ValveState.Closing;
        xEnterMove := TRUE;
    ELSE
        eState := E_ValveState.Intermediate;
    END_IF
END_IF
//     время хода: отсчёт заново с каждого начала движения. Концевик положения подключён (у
//     закрытия — или закрытие по моменту) — таймаут = отказ; не подключён — положение по времени
IF xEnterMove THEN
    fbTravel.Preset(xValue := FALSE);
END_IF
fbTravel(xIn := eState = E_ValveState.Opening OR eState = E_ValveState.Closing, tOnDelay := stCfgLkg.tTravel,
         itfTime := itfTimeAct);
IF fbTravel.xOut THEN
    IF eState = E_ValveState.Opening THEN
        IF stCfgLkg.xZsoUsed THEN
            xFltFailOpen := TRUE;
            eState := E_ValveState.Fault;
        ELSE
            eState := E_ValveState.Open;
        END_IF
    ELSIF eState = E_ValveState.Closing THEN
        IF stCfgLkg.xZscUsed OR stCfgLkg.xCloseOnTorque THEN
            xFltFailClose := TRUE;
            eState := E_ValveState.Fault;
        ELSE
            eState := E_ValveState.Closed;
        END_IF
    END_IF
END_IF

//     крайнее положение подтверждено концевиком (по времени хода и «по моменту» — нет): только
//     такое положение контролируется на уход с концевика
IF (eState = E_ValveState.Open AND xAtOpen) OR (eState = E_ValveState.Closed AND xAtClose) THEN
    xEndByLs := TRUE;
ELSIF eState <> E_ValveState.Open AND eState <> E_ValveState.Closed THEN
    xEndByLs := FALSE;
END_IF
