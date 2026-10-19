// Назначение: уставки станции (GVL_Persist.stStationCfg) — параметры 04 §18.2 № 2–31 с теми же
//             именами и значениями по умолчанию, тревоги KNS1.* и резерв. Значения по умолчанию
//             проходят F_StationCfgCheck. Тип лежит в Persistent Variables и заморожен целиком:
//             новые параметры 1.x — в элементах резерва без переименования.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
TYPE ST_StationCfg :
STRUCT
    // уровни (№ 2–6)
    rLvlStop_m          : REAL := 1.00;
    rLvlStartLead_m     : REAL := 1.60;
    rLvlStopAssist_m    : REAL := 1.40;
    rLvlStartAssist_m   : REAL := 2.40;
    tLvlConfirm         : TIME := T#5S;
    // ступенчатое (№ 7)
    rStepSpeed_pct      : REAL := 100.0;
    // ПИД (№ 8–12)
    rLevelSp_m          : REAL := 1.40;
    rAssistOn_pct       : REAL := 98.0;
    tAssistOn           : TIME := T#30S;
    rAssistOff_pct      : REAL := 75.0;
    tAssistOff          : TIME := T#60S;
    // роли (№ 13–17)
    uiDutyMax           : UINT := 2;
    eRotation           : E_RotationMode := E_RotationMode.RunHours;
    tMaxContRun         : TIME := T#4H;
    tOverlap            : TIME := T#10S;
    tStagger            : TIME := T#5S;
    // питание (№ 18–20)
    tPwrRestart         : TIME := T#10S;
    tSeqStep            : TIME := T#15S;
    tPlcStart           : TIME := T#10S;
    // защиты (№ 21–27)
    tDryRelease         : TIME := T#60S;
    rLdev102On_m        : REAL := 3.50;
    rLdev102Off_m       : REAL := 4.40;
    rLdev103On_m        : REAL := 0.80;
    rLdev103Off_m       : REAL := 0.20;
    tLdev               : TIME := T#30S;
    tLtRecover          : TIME := T#30S;
    // недогрузка (№ 28–30)
    rUnderload_A        : REAL := 12.0;
    rUnderloadSpeed_pct : REAL := 80.0;
    tUnderload          : TIME := T#15S;
    // вентиляция (№ 31)
    tV1Overrun          : TIME := T#10M;
    // тревоги KNS1.* по 05_alarm_list.csv (source = station), индекс — E_StationAlarm. Задержка появления
    // в 05 = tOnDelay + выдержка логики (LDEV — tLdev, UL1…UL3 — tUnderload). Инициализатор — весь
    // массив целиком (правило 3 API 18.3)
    astAlarm            : ARRAY[1..GVL_Const.STN_ALARM_COUNT] OF PL.ST_AlarmCfg := [
        (ePriority := PL.E_AlarmPriority.Critical, tShelveMax := T#0S),   // 1 EHL: откладывать нельзя
        (ePriority := PL.E_AlarmPriority.High),                          // 2 DRY
        (ePriority := PL.E_AlarmPriority.High, tOnDelay := T#10S),       // 3 LACK
        (ePriority := PL.E_AlarmPriority.High, tOnDelay := T#10S),       // 4 NORES
        (ePriority := PL.E_AlarmPriority.Medium),                        // 5 ATS
        (ePriority := PL.E_AlarmPriority.Medium),                        // 6 FLOAT
        (ePriority := PL.E_AlarmPriority.Medium),                        // 7 LDEV
        (ePriority := PL.E_AlarmPriority.Low, tOnDelay := T#10S),        // 8 STEP: без переходных циклов старта
        (ePriority := PL.E_AlarmPriority.Low, tOnDelay := T#10M),        // 9 NOAUTO
        (ePriority := PL.E_AlarmPriority.Medium),                        // 10 UL1
        (ePriority := PL.E_AlarmPriority.Medium),                        // 11 UL2
        (ePriority := PL.E_AlarmPriority.Medium),                        // 12 UL3
        (ePriority := PL.E_AlarmPriority.Low)];                          // 13 SIM
    // резерв: новые параметры 1.x без смены типа; смысл элемента записывается в DESIGN, раздел 3.1
    arReserve           : ARRAY[0..7] OF REAL;
    atReserve           : ARRAY[0..3] OF TIME;
    auiReserve          : ARRAY[0..3] OF UINT;
END_STRUCT
END_TYPE
