// Назначение: баланс объёма приёмного резервуара: dV = (Qin − Qout)·dt/3600, h = V / S. Уровень
//             хранится в LREAL (приращение за шаг 20 мс — порядка 10⁻⁵ м). Выше rOverflow_m —
//             перелив: уровень ограничен, время перелива растёт, пока приток больше откачки (целые
//             секунды, перелив короче секунды — 1 с; ClearOverflow обнуляет). Ниже SIM_PUMP_INTAKE_M —
//             приёмок насосов осушен (xIntakeDry, по уровню LREAL — его же берёт гидравлика): откачки нет.
//             Шаг dt задаёт вызывающий (FB_PlantModel: шаги не длиннее SIM_DT_SUBSTEP); dt ≤ 0 — уровень
//             не меняется.
// Автор:      kr0nsch
// Версия:     0.1.1
// Документ:   docs/DESIGN.md, раздел 11.2
FUNCTION_BLOCK FB_TankModel
VAR_INPUT
    rInflow_m3h  : REAL;            // приток
    rOutflow_m3h : REAL;            // откачка насосами
    lrDt_s       : LREAL;           // шаг интегрирования
    rArea_m2     : REAL := 12.0;    // площадь зеркала (stSimCfg.rTankArea_m2)
    rOverflow_m  : REAL := 4.60;    // отметка перелива (stSimCfg.rLevelOverflow_m)
END_VAR
VAR_OUTPUT
    rLevel_m      : REAL;           // истинный уровень
    xOverflow     : BOOL;           // идёт перелив
    xIntakeDry    : BOOL;           // уровень ниже приёмка насосов (по lrLevel_m; SetLevel — сразу)
    udiOverflow_s : UDINT;          // время перелива с ClearOverflow, с (был перелив — не меньше 1)
    rVolume_m3    : REAL;           // объём воды
END_VAR
VAR
    lrLevel_m    : LREAL;           // состояние: уровень
    lrOverflow_s : LREAL;           // состояние: время перелива
    lrOut_m3h    : LREAL;           // действующая откачка
END_VAR
