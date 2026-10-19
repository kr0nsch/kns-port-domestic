// Начало цикла задачи: коэффициент ускорения LIMIT(1, rTimeScale, SIM_TIME_SCALE_MAX), не конечное
// значение → 1. При смене коэффициента — перебазирование: время контура продолжается без скачка
METHOD PUBLIC Update
VAR_INPUT
    rTimeScale : REAL;      // запрошенный коэффициент (GVL_Sim.stSimCfg.rTimeScale или 1)
END_VAR
VAR
    lrScaleNew : LREAL;     // коэффициент после ограничения
    ltReal     : LTIME;     // системное время перебазирования
END_VAR
