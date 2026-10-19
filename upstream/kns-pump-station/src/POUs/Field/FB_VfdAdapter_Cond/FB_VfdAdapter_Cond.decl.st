// Назначение: адаптер ПЧ по условной карте регистров (не карта реального производителя, ARCHITECTURE,
//             раздел 12): Decode разбирает слово состояния STW и фактическую частоту FACT для PL.FB_MotorVfd,
//             Encode собирает слово управления CTW (бит сброса аварии, пока xQReset) и задание частоты FREF.
//             Пуск — проводом (P10n_RUN), бит пуска в CTW не используется. Без связи слово состояния
//             недостоверно: готовность, работа, авария, предупреждение, местное — FALSE, скорость — последняя
//             принятая; частоту ПЧ задаёт его сторожевой таймер (04 §12). Другая модель ПЧ — другой адаптер
//             с теми же выходами.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 8.2; docs/ARCHITECTURE.md, раздел 12
FUNCTION_BLOCK FB_VfdAdapter_Cond
VAR_OUTPUT
    xCommOk       : BOOL;           // xSlaveOk последнего Decode
    xReady        : BOOL;           // STW.0 (при связи; без связи — FALSE)
    xRunning      : BOOL;           // STW.1
    xFault        : BOOL;           // STW.2
    xWarning      : BOOL;           // STW.3 (HMI)
    xRemote       : BOOL;           // STW.4 (HMI)
    rSpeedAct_pct : REAL;           // FACT / VFD_COUNTS_PER_PCT; без связи — последнее значение
    wCtw          : WORD;           // слово управления (Encode)
    uiFref        : UINT;           // задание частоты, 0,01 Гц (Encode)
END_VAR
