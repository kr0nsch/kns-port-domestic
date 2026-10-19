// 1. Время этого вызова — один раз, для задержек и для отметок событий
IF itfTime <> 0 THEN
    itfTimeAct := itfTime;
ELSE
    itfTimeAct := fbSysTime;
END_IF
ltNow := itfTimeAct.Now();

// 2. Действующий приоритет: значение вне перечисления (мусор persistent-памяти) считается Medium.
//    Строгое перечисление защищает только исходный текст, поэтому проверка — сравнениями
IF stCfg.ePriority = E_AlarmPriority.None OR stCfg.ePriority = E_AlarmPriority.Low
   OR stCfg.ePriority = E_AlarmPriority.Medium OR stCfg.ePriority = E_AlarmPriority.High
   OR stCfg.ePriority = E_AlarmPriority.Critical
THEN
    ePrioAct := stCfg.ePriority;
ELSE
    ePrioAct := E_AlarmPriority.Medium;
END_IF

IF ePrioAct = E_AlarmPriority.None THEN
    // 3. Тревога выключена: Normal, все выходы FALSE, запросы и shelve снимаются. Если тревога была не в
    //    Normal — один переход с событием Disabled (ALM-1): журнал и сводка по событиям закрывают её; дальше
    //    событий нет. Отсчёт задержки начнётся заново после включения приоритета
    fbDelay.Preset(xValue := FALSE);
    IF eState <> E_AlarmState.Normal THEN
        Transit(eNew := E_AlarmState.Normal, eReason := E_AlarmEventReason.Disabled);
    END_IF
    xActive := FALSE;
    xShelved := FALSE;
    xAckReq := FALSE;
    xShelveReq := FALSE;
    xUnshelveReq := FALSE;
ELSE
    // 4. Условие после задержек появления и снятия
    fbDelay(xIn := xIn, tOnDelay := stCfg.tOnDelay, tOffDelay := stCfg.tOffDelay, itfTime := itfTimeAct);
    xActive := fbDelay.xOut;

    // 5. Квитирование — против состояния на начало вызова; в остальных состояниях без эффекта
    IF xAckReq THEN
        IF eState = E_AlarmState.ActiveUnack THEN
            Transit(eNew := E_AlarmState.ActiveAck, eReason := E_AlarmEventReason.Acked);
        ELSIF eState = E_AlarmState.RtnUnack THEN
            Transit(eNew := E_AlarmState.Normal, eReason := E_AlarmEventReason.Acked);
        END_IF
    END_IF
    xAckReq := FALSE;

    // 6. Shelve: снятие командой, истечение срока, новый запрос
    UpdateShelve();

    // 7–8. Наложенные состояния и базовый автомат ISA-18.2
    UpdateState();
END_IF

// 9. Выходы. После шага 6 при xShelved всегда ltShelveEnd > ltNow: разность без переполнения
xUnacked := eState = E_AlarmState.ActiveUnack OR eState = E_AlarmState.RtnUnack;
xInList := xUnacked OR eState = E_AlarmState.ActiveAck;
IF xShelved THEN
    tShelveRemain := LTIME_TO_TIME(ltShelveEnd - ltNow);
ELSE
    tShelveRemain := T#0S;
END_IF
