// Ступенчатый способ — не больше двух насосов (ведущий и подпорный) и не больше uiDutyMax
uiMax := MIN(GVL_Const.STN_DUTY_MAX, stCfg.uiDutyMax);

// 1. Вход без рывка: число насосов — по работающим; выдержки подтверждения — заново
IF xInit THEN
    uiPumps := MIN(uiInitPumps, uiMax);
    fbStartLead.Preset(xValue := FALSE);
    fbStartAssist.Preset(xValue := FALSE);
    fbStopAssist.Preset(xValue := FALSE);
    fbStopAll.Preset(xValue := FALSE);
END_IF
uiPumps := MIN(uiPumps, uiMax);

// 2. Пересечения уровней по диаграмме 04 §6. Условие каждого перехода зависит от состояния: после
//    перехода выдержка следующего начинается заново. Недостоверный уровень — условий нет, состояние
//    держится (сравнения с NaN ложны и без проверки xLevelValid)
fbStartLead(xIn := xLevelValid AND uiPumps = 0 AND rLevel_m >= stCfg.rLvlStartLead_m AND uiMax > 0,
            tOnDelay := stCfg.tLvlConfirm, itfTime := itfTime);
fbStartAssist(xIn := xLevelValid AND uiPumps = 1 AND rLevel_m >= stCfg.rLvlStartAssist_m AND uiMax > 1,
              tOnDelay := stCfg.tLvlConfirm, itfTime := itfTime);
fbStopAssist(xIn := xLevelValid AND uiPumps = 2 AND rLevel_m <= stCfg.rLvlStopAssist_m,
             tOnDelay := stCfg.tLvlConfirm, itfTime := itfTime);
fbStopAll(xIn := xLevelValid AND uiPumps > 0 AND rLevel_m <= stCfg.rLvlStop_m,
          tOnDelay := stCfg.tLvlConfirm, itfTime := itfTime);

// 3. Переход: останов всех старше остальных (2 → 0 одним шагом, если обе выдержки истекли)
IF fbStopAll.xOut THEN
    uiPumps := 0;
ELSIF fbStopAssist.xOut THEN
    uiPumps := 1;
ELSIF fbStartAssist.xOut THEN
    uiPumps := 2;
ELSIF fbStartLead.xOut THEN
    uiPumps := 1;
END_IF

xConfirming := fbStartLead.xTimingOn OR fbStartAssist.xTimingOn OR fbStopAssist.xTimingOn
               OR fbStopAll.xTimingOn;
uiRequired := SEL(xEnable, 0, uiPumps);
rSpeed_pct := stCfg.rStepSpeed_pct;
