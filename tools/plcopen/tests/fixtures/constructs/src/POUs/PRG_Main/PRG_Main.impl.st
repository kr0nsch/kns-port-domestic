(* вызовы всех объектов примера *)
itfDevice := fbMotor;
itfReset := fbMotor;
fbMotor(stCmd := stCmd);
IF itfDevice <> 0 THEN
    itfDevice.Mode := E_Mode.Auto;
    xOk := itfDevice.Fault;
END_IF
itfReset.Reset(xForce := TRUE);
fbCounter(xIn := GVL_Io.xDiStart, stCmd := GVL_Io.astCmd[GVL_Io.IO_CHANNELS - 1]);
GVL_Io.xDoRun := fbMotor.xRun;
stSts.xRun := fbMotor.xRun;
stSts.uiStarts := fbMotor.Starts;
rOut := F_Clamp(rValue := INT_TO_REAL(GVL_Io.iAiLevel), rMin := 0.0, rMax := 100.0);
lrSum := F_Sum(arValues := arBuf);
pValue := ADR(rOut);
refValue REF= rOut;
IF __ISVALIDREF(refValue) THEN
    refValue := refValue + GVL_Const.RATE_LIMIT;
END_IF
uRaw.wWord := 16#1234;
stDerived.tDelay := T#1S;
CASE iStep OF
    0:
        iStep := 1;
    1, 2:
        iStep := iStep + 1;
ELSE
    iStep := 0;
END_CASE
WHILE iStep > 10 DO
    iStep := iStep - 1;
END_WHILE
REPEAT
    iStep := iStep + 0;
UNTIL TRUE
END_REPEAT
GVL_Io.udiRunHours := GVL_Io.udiRunHours + fbCounter.udiCount;
PersistentVars.udiStartsTotal := PersistentVars.udiStartsTotal + fbMotor.Starts;
sName := GVL_Const.TEXT_OK;
eColor := E_Color.Blue;
ePercent := 75;
PRG_Aux();
