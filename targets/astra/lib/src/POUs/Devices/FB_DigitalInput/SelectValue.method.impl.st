IF NOT xCfgEverOk THEN
    // безопасное значение: корректной Cfg ещё не было
    xValue := FALSE;
    xValid := FALSE;
ELSIF eMode = E_DeviceMode.OutOfService THEN
    // значение удерживается
    xValid := FALSE;
ELSIF eMode = E_DeviceMode.Manual THEN
    xValue := xSubst;
    xValid := TRUE;
ELSIF xChannelFault THEN
    // значение отказа: тело выставило xGood по eFailValue (HoldLast — значение до отказа)
    xValue := xGood;
    xValid := FALSE;
ELSE
    xValue := xGood;
    xValid := TRUE;
END_IF
