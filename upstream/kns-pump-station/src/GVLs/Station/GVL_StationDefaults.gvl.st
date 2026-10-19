// Назначение: уставки станции и LIC101 по умолчанию — команда «Применить уставки проекта»
//             (GVL_Hmi.xApplyProjectCfg, 04 §18.3). Имена — как у переменных GVL_Persist; значения
//             LIC101 — тот же инициализатор, что в блоке станции GVL_Persist (DESIGN, раздел 4.7):
//             их совпадение сверяет тест StationDefaultsMatchPersistInit.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 4.2
{attribute 'qualified_only'}
VAR_GLOBAL CONSTANT
    // Умолчания типа (раздел 3.1). Инициализатор нужен компилятору (без него C0228); остальные поля —
    // умолчания ST_StationCfg, совпадение с типом сверяет тест StationDefaultsMatchTypeDefaults.
    // lint:allow STL007 имя как у переменной GVL_Persist (DESIGN 4.2)
    stStationCfg : ST_StationCfg := (eRotation := E_RotationMode.RunHours);
    // lint:allow STL007 имя как у переменной GVL_Persist (DESIGN 4.2); LIC101 (04 §18.2, № 32–43)
    stLIC101Cfg  : PL.ST_PidCfg := (
        eAction := PL.E_PidAction.Direct, rKp := 6.0, rTi_s := 600.0, rTd_s := 0.0,
        rPvMin_eu := 0.0, rPvMax_eu := 5.0, rSpMin_eu := 1.2, rSpMax_eu := 2.2,
        rOutMin_pct := 0.0, rOutMax_pct := 100.0, tSample := T#500MS,
        ePvFailAction := PL.E_PidPvFailAction.Hold, rSafeOut_pct := 100.0, xUseOutAct := TRUE,
        udiAlarmIdBase := 100100,
        astAlarm := [(ePriority := PL.E_AlarmPriority.None), (ePriority := PL.E_AlarmPriority.None),
                     (ePriority := PL.E_AlarmPriority.None), (ePriority := PL.E_AlarmPriority.None),
                     (ePriority := PL.E_AlarmPriority.None), (ePriority := PL.E_AlarmPriority.None),
                     (ePriority := PL.E_AlarmPriority.None), (ePriority := PL.E_AlarmPriority.None)]);
END_VAR
