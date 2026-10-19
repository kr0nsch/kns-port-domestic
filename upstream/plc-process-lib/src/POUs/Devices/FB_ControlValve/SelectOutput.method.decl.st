// Шаг 6.4: выбор выхода по старшинству (раздел 16.3 контракта): нет корректной Cfg — положение
// безопасности из поданной Cfg; OutOfService — удержание; Local — следит за ОС (в пределах 0…100 %);
// блокировка или отказ с SafePos — rSafePos_pct мимо пределов и рампы; отказ с Hold — удержание;
// Auto/Manual — пределы и рампа (LREAL, F_RateLimitLr). lrRamp_pct — положение до плотного закрытия. Значения из
// VAR_IN_OUT — параметрами (R2).
// Шаг тела FB_ControlValve; внутренний: PROTECTED (правило L5 контракта), имя зарезервировано
METHOD PROTECTED SelectOutput
VAR_INPUT
    rManSp_pct      : REAL;   // stCmd.rPosSpMan_pct — задание оператора, %
    rCfgSafePos_pct : REAL;   // stCfg.rSafePos_pct — положение безопасности поданной Cfg, %
END_VAR
VAR
    rSpRaw    : REAL;         // задание до пределов, %
    rSafe_pct : REAL;         // положение безопасности без корректной Cfg, %
END_VAR
