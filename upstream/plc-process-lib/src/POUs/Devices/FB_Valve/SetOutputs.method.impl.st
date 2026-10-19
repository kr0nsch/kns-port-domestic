// 6.8 Выходы. Без управления и при отказе выходы сняты, катушка обесточена (положение пружины)
IF NOT xDrive OR eState = E_ValveState.Fault OR xMotorized THEN
    eSolCmd := E_ValveState.Intermediate;
ELSIF eState = E_ValveState.Opening OR (eState = E_ValveState.Open AND eTarget = E_ValveState.Open) THEN
    eSolCmd := E_ValveState.Open;
ELSIF eState = E_ValveState.Closing OR (eState = E_ValveState.Closed AND eTarget = E_ValveState.Closed) THEN
    eSolCmd := E_ValveState.Closed;
END_IF
xOutEn := xDrive AND eState <> E_ValveState.Fault;
//     аварийный ход в положение безопасности (VLV-20) — только при отказе (eState = Fault): с обычными выходами не
//     пересекается
xQOpen := (xOutEn AND xMotorized AND eState = E_ValveState.Opening)
          OR (xSafeMove AND eSafeDir = E_ValveState.Opening);
xQClose := (xOutEn AND xMotorized AND eState = E_ValveState.Closing)
           OR (xSafeMove AND eSafeDir = E_ValveState.Closing);
xQCoil := xOutEn AND ((stCfgLkg.eType = E_ValveType.SolenoidEto AND eSolCmd = E_ValveState.Open)
                      OR (stCfgLkg.eType = E_ValveType.SolenoidEtc AND eSolCmd = E_ValveState.Closed));
xOpened := eState = E_ValveState.Open OR (eState = E_ValveState.Fault AND xAtOpen AND NOT xAtClose);
xClosed := eState = E_ValveState.Closed OR (eState = E_ValveState.Fault AND xAtClose AND NOT xAtOpen);
//     выбег привода: последнее включённое направление и отсчёт tReverse от снятия выхода (DriveToTarget)
IF xQOpen THEN
    eLastDir := E_ValveState.Opening;
ELSIF xQClose THEN
    eLastDir := E_ValveState.Closing;
END_IF
fbRunOff(xIn := xQOpen OR xQClose, tOffDelay := stCfgLkg.tReverse, itfTime := itfTimeAct);
