// 6.5 Автомат состояний: отказ, снятие отказа, останов без управления
xFaultAny := xFltFailOpen OR xFltFailClose OR xFltPosLost OR xFltTorque OR xFltExt OR xBothLimits;
xDrive := xRemote AND xCfgEverOk AND xPowerOk AND NOT xFaultAny;
IF xFirstCall THEN
    // старт ПЛК: состояние по концевикам; Manual: цель := текущее положение
    eState := LimitPosition();
    IF eState = E_ValveState.Open OR eState = E_ValveState.Closed THEN
        eLastEnd := eState;
    END_IF
    eManTarget := CurrentTarget();
END_IF
IF xFaultAny THEN
    eState := E_ValveState.Fault;
    eManTarget := E_ValveState.Intermediate;   // после Reset арматура в Manual сама не двинется
ELSIF eState = E_ValveState.Fault THEN
    eState := LimitPosition();                 // отказы сняты: далее — по концевикам
ELSIF NOT xDrive AND (eState = E_ValveState.Opening OR eState = E_ValveState.Closing
                      OR eState = E_ValveState.Reversing)
THEN
    eState := E_ValveState.Intermediate;       // выходы сняты: нет напряжения, Local, OOS
END_IF
IF NOT xPowerOk THEN
    eManTarget := E_ValveState.Intermediate;   // нет напряжения: Manual стоит, цель снята
END_IF

// 6.6 Без движения — состояние по концевикам. При контроле уход с концевика и «оба концевика»
//     держат состояние до срабатывания фильтра (дальше — Fault)
IF eState = E_ValveState.Open OR eState = E_ValveState.Closed OR eState = E_ValveState.Intermediate
   OR eState = E_ValveState.Unknown
THEN
    //  положение «по времени» (не подтверждённое своим концевиком) держится, только пока арматурой
    //  управляет ПЛК: в Local и OOS её двигают с места или руками, соленоид без тока катушки уходит на
    //  пружину. Дальше — только по концевикам (без концевиков — Unknown)
    xCoilEnd := (stCfgLkg.eType = E_ValveType.SolenoidEto AND eState = E_ValveState.Open)
                OR (stCfgLkg.eType = E_ValveType.SolenoidEtc AND eState = E_ValveState.Closed);
    IF (eState = E_ValveState.Open OR eState = E_ValveState.Closed) AND NOT xEndByLs
       AND (NOT xRemote OR (xCoilEnd AND NOT xDrive))
    THEN
        eState := LimitPosition();
    END_IF
    xLeftEnd := xEndByLs AND ((eState = E_ValveState.Open AND NOT xAtOpen)
                              OR (eState = E_ValveState.Closed AND NOT xAtClose));
    IF NOT (xLeftEnd AND xPosSup) THEN
        IF xAtOpen AND xAtClose THEN
            IF NOT xSupervise THEN
                eState := E_ValveState.Unknown;
            END_IF
        ELSIF xAtOpen THEN
            eState := E_ValveState.Open;
        ELSIF xAtClose THEN
            eState := E_ValveState.Closed;
        ELSIF xLeftEnd THEN
            eState := E_ValveState.Intermediate;
        END_IF
    END_IF
END_IF
