fbTon(IN := TRUE, PT := T#1S);
iLen := Standard.LEN('abc');
fbBlink(ENABLE := TRUE, TIMELOW := T#1S, TIMEHIGH := T#1S);
Mem.iValue := iLen;
dwRaw := %ID4;
ulTime := SysTimeRtcHighResGet(ulTime);
fbMotor(stCfg := PL.GVL_Const.CFG);
