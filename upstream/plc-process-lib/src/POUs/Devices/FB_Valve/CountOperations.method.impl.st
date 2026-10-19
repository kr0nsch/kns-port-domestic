// 6.9 Счётчики: цикл — вход в Open, если прошлое крайнее положение не Open; время работы — пока
//     включён выход привода (шаг не больше DT_ACCUM_MAX), целые секунды — в stRetain
IF eState = E_ValveState.Open AND eLastEnd <> E_ValveState.Open THEN
    stValveRet.udiOpCount := stValveRet.udiOpCount + 1;
    stValveRet.udiOpCountMaint := stValveRet.udiOpCountMaint + 1;
END_IF
IF eState = E_ValveState.Open OR eState = E_ValveState.Closed THEN
    eLastEnd := eState;
END_IF
IF xActPrev THEN
    ltActAccum := ltActAccum + MIN(ltDt, GVL_Const.DT_ACCUM_MAX);
END_IF
WHILE ltActAccum >= LTIME#1S DO
    ltActAccum := ltActAccum - LTIME#1S;
    stValveRet.udiOpTime_s := stValveRet.udiOpTime_s + 1;
    stValveRet.udiOpTimeMaint_s := stValveRet.udiOpTimeMaint_s + 1;
END_WHILE
xActPrev := xQOpen OR xQClose;
