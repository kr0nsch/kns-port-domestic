(* внешний (* вложенный *) комментарий *)
itfPos := fbValve;
itfLock := fbValve;
itfPos.Setpoint := 50.0;
itfPos.MoveTo(rPos_pct := 40.0);
itfLock.Lock(xLock := NOT xDoRun);
fbValve();
Step(iInc := 1);
F_Noop(xIn := TRUE);
IF iCalls > 5 AND_THEN fbValve.rPos_pct < 1.0E3 THEN
    iCalls := 0;
END_IF
