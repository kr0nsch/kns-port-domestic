PickCandidate := 0;
IF xNeedComm THEN
    PickCandidate := PickIn(eRot := eRot, uiNext := uiNext, xRequireCommOk := TRUE, xRequireReady := TRUE);
    IF PickCandidate = 0 AND NOT xReadyOnly THEN
        PickCandidate := PickIn(eRot := eRot, uiNext := uiNext, xRequireCommOk := TRUE, xRequireReady := FALSE);
    END_IF
END_IF
// передача роли ведущего в ПИД — только насосу со связью: без неё после перекрытия ПИД потерял бы готовность
// и станция ушла бы в ступенчатое (04 §5.2 п. 3); нет такого — повтор передачи позже
IF PickCandidate = 0 AND NOT (xNeedComm AND xReadyOnly) THEN
    PickCandidate := PickIn(eRot := eRot, uiNext := uiNext, xRequireCommOk := FALSE, xRequireReady := TRUE);
    IF PickCandidate = 0 AND NOT xReadyOnly THEN
        PickCandidate := PickIn(eRot := eRot, uiNext := uiNext, xRequireCommOk := FALSE, xRequireReady := FALSE);
    END_IF
END_IF
