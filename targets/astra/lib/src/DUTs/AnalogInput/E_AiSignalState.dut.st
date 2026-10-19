// Назначение: мгновенная классификация сигнала аналогового входа (до задержки
//             подтверждения). Границы NE 43 — сверить с NAMUR NE 43 (A-02).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_AnalogInput.md
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_AiSignalState :
(
    Good         := 0,
    UnderRange   := 1,   // 3,6 < I < 3,8 мА
    OverRange    := 2,   // 20,5 < I < 21,0 мА
    FailLow      := 3,   // I <= 3,6 мА
    FailHigh     := 4,   // I >= 21,0 мА
    ChannelFault := 5,   // xChannelFault
    NotFinite    := 6    // NaN, ±Inf, |rIn| > REAL_SANE_MAX
) INT;
END_TYPE
