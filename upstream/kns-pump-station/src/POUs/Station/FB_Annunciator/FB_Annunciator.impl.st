// 1. Счётчики по приоритетам (индекс — значение E_AlarmPriority: Low = 1 … Critical = 4)
uiUnackMed := 0;
uiUnackHigh := 0;
uiActMed := 0;
uiActHigh := 0;
FOR uiPrio := TO_UINT(PL.E_AlarmPriority.Medium) TO GVL_Const.ALM_PRIO_COUNT DO
    uiUnackMed := uiUnackMed + auiUnack[uiPrio];
    uiActMed := uiActMed + auiActive[uiPrio];
    IF uiPrio >= TO_UINT(PL.E_AlarmPriority.High) THEN
        uiUnackHigh := uiUnackHigh + auiUnack[uiPrio];
        uiActHigh := uiActHigh + auiActive[uiPrio];
    END_IF
END_FOR

// 2. Сирена: «Звук» выключает, новая High/Critical включает снова (новая старше команды того же
//    цикла), квитирование всех High/Critical — выключает
IF xFirstCall THEN
    udiSeqPrev := udiNewHighSeq;
END_IF
IF xSilence THEN
    xHorn := FALSE;
END_IF
IF udiNewHighSeq <> udiSeqPrev THEN
    xHorn := TRUE;
END_IF
IF uiUnackHigh = 0 THEN
    xHorn := FALSE;
END_IF
udiSeqPrev := udiNewHighSeq;

// 3. Лампа: мигание 1 Гц по времени источника (фаза «горит» — с начала мигания), иначе горит при
//    активных; «время назад» начинает мигание заново
IF itfTime <> 0 THEN
    ltNow := itfTime.Now();
ELSE
    ltNow := fbSysTime.Now();
END_IF
IF uiUnackMed > 0 THEN
    IF NOT xBlinking OR ltNow < ltBlinkStart THEN
        ltBlinkStart := ltNow;
    END_IF
    xBlinking := TRUE;
    uliHalf := LTIME_TO_ULINT(TIME_TO_LTIME(GVL_Const.STN_LAMP_HALF_PERIOD));
    IF uliHalf > 0 THEN
        xLamp := ((LTIME_TO_ULINT(ltNow - ltBlinkStart) / uliHalf) MOD 2) = 0;
    ELSE
        xLamp := TRUE;
    END_IF
ELSE
    xBlinking := FALSE;
    xLamp := uiActMed > 0;
END_IF

// 4. Реле «Общая авария»: под напряжением в норме
xK1Energized := uiActHigh = 0;
xFirstCall := FALSE;
