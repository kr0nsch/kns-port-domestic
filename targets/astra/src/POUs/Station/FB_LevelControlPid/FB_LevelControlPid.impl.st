// Способ ПИД — не больше двух насосов (ведущий и подпорный) и не больше uiDutyMax
uiMax := MIN(GVL_Const.STN_DUTY_MAX, stCfg.uiDutyMax);
xLeadValid := uiLead >= 1 AND uiLead <= GVL_Const.STN_PUMP_COUNT;
IF xLeadValid THEN
    xLeadValid := aitfPump[uiLead] <> 0;
END_IF

// 1. Слежение (04 §7.3): ПИД управляет, только когда выбран, а ведущий работает в Auto без отказа
//    (SpeedAutoActive) и со связью с ПЧ; иначе выход следует за заданием ведущего (0 — ведущего нет)
xPidControls := FALSE;
rTrack_pct := 0.0;
IF xLeadValid THEN
    rTrack_pct := aitfPump[uiLead].SpeedRef;
    xPidControls := xEnable AND aitfPump[uiLead].SpeedAutoActive AND axCommOk[uiLead];
END_IF
xTrack := NOT xPidControls;

// 2. Готовность (04 §7.4): ПИД в Auto, уровень годен и есть насос со связью — среди работающих в
//    Auto, а если насосы стоят — среди доступных. Если насосы есть, но связи нет ни у одного, —
//    потеря связи: готовность снимается сразу и возвращается через STN_PID_RECOVER (04 §12)
xAnyRunning := FALSE;
xCommRunning := FALSE;
xCommAvailable := FALSE;
xAnyAvailable := FALSE;
FOR uiPump := 1 TO GVL_Const.STN_PUMP_COUNT DO
    IF aitfPump[uiPump] <> 0 THEN
        IF aitfPump[uiPump].Running AND aitfPump[uiPump].Mode = PL.E_DeviceMode.Auto THEN
            xAnyRunning := TRUE;
            xCommRunning := xCommRunning OR axCommOk[uiPump];
        END_IF
        IF aitfPump[uiPump].Available THEN
            xAnyAvailable := TRUE;
            xCommAvailable := xCommAvailable OR axCommOk[uiPump];
        END_IF
    END_IF
END_FOR
xCommPart := SEL(xAnyRunning, xCommAvailable, xCommRunning);
xCommBlock := SEL(xAnyRunning, xAnyAvailable, TRUE) AND NOT xCommPart;
IF xFirstCall THEN
    fbCommRecover.Preset(xValue := TRUE);           // при старте выдержки возврата нет
END_IF
fbCommRecover(xIn := NOT xCommBlock, tOnDelay := GVL_Const.STN_PID_RECOVER, itfTime := itfTime);
xPidReady := ePidMode = PL.E_DeviceMode.Auto AND xLevelValid AND xCommPart AND fbCommRecover.xOut;

// 3. Вход без рывка: число насосов — по работающим, выдержки — заново
IF xInit THEN
    uiPumps := MIN(uiInitPumps, uiMax);
    fbStartLead.Preset(xValue := FALSE);
    fbAssistOnOut.Preset(xValue := FALSE);
    fbAssistOnLvl.Preset(xValue := FALSE);
    fbAssistOff.Preset(xValue := FALSE);
    fbStopAll.Preset(xValue := FALSE);
END_IF
uiPumps := MIN(uiPumps, uiMax);

// 4. Число насосов (таблица 04 §7.2). Условия по выходу ПИД — только когда ПИД управляет: выход
//    в слежении повторяет задание ведущего и о нагрузке не говорит. Недостоверный уровень —
//    условий по уровню нет, состояние держится
fbStartLead(xIn := xLevelValid AND uiPumps = 0 AND uiMax > 0 AND rLevel_m >= stCfg.rLvlStartLead_m,
            tOnDelay := stCfg.tLvlConfirm, itfTime := itfTime);
fbAssistOnOut(xIn := xPidControls AND uiPumps = 1 AND uiMax > 1 AND rPidOut_pct >= stCfg.rAssistOn_pct,
              tOnDelay := stCfg.tAssistOn, itfTime := itfTime);
fbAssistOnLvl(xIn := xLevelValid AND uiPumps = 1 AND uiMax > 1 AND rLevel_m >= stCfg.rLvlStartAssist_m,
              tOnDelay := stCfg.tLvlConfirm, itfTime := itfTime);
fbAssistOff(xIn := xPidControls AND uiPumps = 2 AND rPidOut_pct <= stCfg.rAssistOff_pct
                   AND xLevelValid AND rLevel_m < stCfg.rLvlStartAssist_m,
            tOnDelay := stCfg.tAssistOff, itfTime := itfTime);
fbStopAll(xIn := xLevelValid AND uiPumps > 0 AND rLevel_m <= stCfg.rLvlStop_m,
          tOnDelay := stCfg.tLvlConfirm, itfTime := itfTime);

IF fbStopAll.xOut THEN
    uiPumps := 0;
ELSIF fbAssistOff.xOut THEN
    uiPumps := 1;
ELSIF fbAssistOnOut.xOut OR fbAssistOnLvl.xOut THEN
    uiPumps := 2;
ELSIF fbStartLead.xOut THEN
    uiPumps := 1;
END_IF

uiRequired := SEL(xEnable, 0, uiPumps);
xFirstCall := FALSE;
