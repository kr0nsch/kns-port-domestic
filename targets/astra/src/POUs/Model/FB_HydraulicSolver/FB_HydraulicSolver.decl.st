// Назначение: рабочая точка насосов на общий напорный коллектор по законам подобия. Насос:
//             H_i = H0·s_i² − k_i·q_i², s = f / 50 Гц; сеть: H = (Hgeo − h) + R·Q², Q = Σ q_i; обратные
//             клапаны — q_i = 0 при H0·s_i² ≤ H. Напор — бисекцией на [Hgeo − h, max(H0·s_i²)]
//             (SIM_SOLVER_ITERATIONS шагов): так решаются и разные частоты. Сухой ход насоса и
//             осушенный приёмок — подача 0 и ток холостого хода; засор — k_i·SIM_CLOG_K_FACTOR, ток
//             ×SIM_CLOG_I_FACTOR к току того же насоса в сети без засора (второе решение; только у насоса,
//             который может подавать). Давление PT201 (у дна, условно):
//             ρ·g·(H + h)/10⁵ бар; насосы стоят — столб за обратными клапанами ρ·g·Hgeo/10⁵.
// Автор:      kr0nsch
// Версия:     0.1.1
// Документ:   docs/DESIGN.md, разделы 11.2, 11.3; эталон tools_project/plant_reference.py
FUNCTION_BLOCK FB_HydraulicSolver
VAR_INPUT
    arSpeed    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // s = f / 50 Гц; ≤ 0 — насос не вращается
    axAirLock  : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // сухой ход насоса (stFaultInj.axAirLock)
    axClog     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // засор (stFaultInj.axClog)
    rLevel_m   : REAL;              // уровень в резервуаре
    xIntakeDry : BOOL;              // приёмок осушен (FB_TankModel.xIntakeDry)
    stPump     : ST_PumpModelCfg;   // характеристика насоса и сети
END_VAR
VAR_OUTPUT
    arFlow_m3h   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // подачи насосов
    arCurrent_A  : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // токи двигателей
    rFlow_m3h    : REAL;            // подача станции (FT202)
    rHead_m      : REAL;            // напор сети
    rPressure_bar : REAL;           // давление в коллекторе (PT201)
END_VAR
VAR
    arQ        : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // подачи последнего решения Solve
    arShutoff  : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // H0·s² (напор при закрытой задвижке)
    arK        : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // действующая крутизна
    axActive   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // насос может подавать
    arS        : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // скорость после проверки
    xAnyClog   : BOOL;              // есть подающий насос с засором (нужно второе решение)
    rHeadClean : REAL;              // напор сети без засоров
    uiPump     : UINT;              // индекс насоса
END_VAR
