// Условия работы с выбегом после снятия (задержка отключения)
fbOverrun(xIn := xGasHigh OR xDoorOpen OR xTempHigh, tOffDelay := stCfg.tV1Overrun, itfTime := itfTime);

// Пожар: запрос снят и блокировка устройства — В1 не раздувает очаг (04 §17)
xRun := fbOverrun.xOut AND NOT xFire;
wInterlock := 0;
IF xFire THEN
    wInterlock := GVL_Const.V1_ILK_FIRE;
END_IF
