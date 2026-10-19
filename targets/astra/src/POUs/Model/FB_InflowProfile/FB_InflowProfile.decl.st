// Назначение: суточный профиль притока: множитель f(tod) — линейная интерполяция точек профиля
//             (точка i — начало часа i, после 23 ч — снова точка 0), приток = rAverage_m3h · f.
//             Время суток приводится к [0, 24) по модулю; неконечное — как 0 ч. Среднее профиля
//             по умолчанию — 1,0: среднесуточный приток равен rAverage_m3h.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 11.2, 11.3
FUNCTION_BLOCK FB_InflowProfile
VAR_INPUT
    rTimeOfDay_h : REAL;            // время суток модели, ч
    rAverage_m3h : REAL;            // средний приток (stSimCfg.rInflowAvg_m3h)
END_VAR
VAR_IN_OUT CONSTANT
    arProfile : ARRAY[0..GVL_Const.SIM_PROFILE_POINTS - 1] OF REAL;   // множители по часам (stSimCfg.arDailyProfile)
END_VAR
VAR_OUTPUT
    rFactor     : REAL;             // множитель профиля
    rInflow_m3h : REAL;             // приток по профилю, не меньше 0
END_VAR
VAR
    rTod_h   : REAL;                // время суток в [0, 24)
    rPos     : REAL;                // позиция в точках профиля
    diIndex  : DINT;                // точка слева
    uiLeft   : UINT;
    uiRight  : UINT;                // точка справа (по кругу)
END_VAR
