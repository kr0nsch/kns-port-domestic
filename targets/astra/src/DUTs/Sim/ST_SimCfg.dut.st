// Назначение: параметры модели и ускорение контура (GVL_Sim.stSimCfg). Значения по умолчанию —
//             условные (DESIGN 11.3), согласованы с 04 и 06.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 3.3, 11.3
{attribute 'qualified_only'}
TYPE ST_SimCfg :
STRUCT
    rTimeScale        : REAL := 1.0;        // 1…SIM_TIME_SCALE_MAX: ускорение всего контура (ARCHITECTURE, раздел 11)
    rTankArea_m2      : REAL := 12.0;
    rLevelOverflow_m  : REAL := 4.60;
    rLevelInit_m      : REAL := 1.20;
    rInflowAvg_m3h    : REAL := 70.0;
    arDailyProfile    : ARRAY[0..GVL_Const.SIM_PROFILE_POINTS - 1] OF REAL := [0.55, 0.45, 0.40, 0.38, 0.40, 0.55,
                            0.92, 1.35, 1.60, 1.50, 1.30, 1.15, 1.10, 1.05, 1.00, 1.00, 1.00, 1.15, 1.35, 1.50,
                            1.45, 1.20, 0.95, 0.70];
    udiSeed           : UDINT := 20261016;  // генератор ливней (одинаковый seed — одинаковые ливни)
    uiStormsPerDayMax : UINT := 2;          // не больше SIM_STORMS_MAX
    rStormPeakMin_m3h : REAL := 100.0;
    rStormPeakMax_m3h : REAL := 250.0;
    tStormMin         : TIME := T#20M;
    tStormMax         : TIME := T#90M;
    rStartTimeOfDay_h : REAL := 0.0;        // время суток модели при старте; демонстрация задаёт его командой
    stPump            : ST_PumpModelCfg;
    tVfdAccel         : TIME := T#10S;      // разгон ПЧ 0 → 50 Гц
    tVfdBoot          : TIME := T#5S;       // готовность ПЧ после подачи питания
    rH2SBase_mgm3     : REAL := 0.6;        // фон газов и температура павильона (условно)
    rCh4Base_pctLel   : REAL := 1.5;
    rAirTemp_C        : REAL := 18.0;
END_STRUCT
END_TYPE
