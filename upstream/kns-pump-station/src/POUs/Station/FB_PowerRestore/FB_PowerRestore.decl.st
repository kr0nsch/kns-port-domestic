// Назначение: питание и последовательный пуск (04 §13). Первый вызов — «задержка» tPlcStart
//             (выходы устройств ещё не посчитаны: xPowerOk первого вызова не используется);
//             напряжение пропало — «нет напряжения», запросов нет (событие 101008); вернулось —
//             «задержка» tPwrRestart (событие 101009); затем шаги: разрешён k-й запрос, следующий —
//             через tSeqStep после подтверждения k пусков или через STN_SEQ_START_TIMEOUT, если пуск
//             не подтвердился (АВР уже назначил замену); конец — разрешено не меньше требуемого
//             (событие 101010, значение — число разрешённых пусков).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.9; docs/04_algorithms.md, раздел 13
FUNCTION_BLOCK FB_PowerRestore
VAR_INPUT
    xPowerOk           : BOOL;      // fbES301.xValue (подтверждение 3 с — задержка DI)
    uiRequired         : UINT;      // от действующего управления
    uiRunningRequested : UINT;      // FB_PumpRotation: запрошены и работают
    itfTime            : PL.I_TimeSource;
    itfEvents          : I_StationEventSink;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // tPwrRestart, tSeqStep, tPlcStart
END_VAR
VAR_OUTPUT
    xPowerLost     : BOOL;
    xRestart       : BOOL;          // задержка после восстановления (старта) или последовательный пуск
    uiRequestLimit : UINT;          // 0 — нет запросов; k — шаг k; STN_PUMP_COUNT — без ограничения
    uiSeqRemain_s  : UINT;          // до следующего шага, с (вверх)
END_VAR
VAR
    xFirstCall   : BOOL := TRUE;    // первый вызов: задержка tPlcStart
    xLost        : BOOL;            // состояние «нет напряжения»
    xDelay       : BOOL;            // состояние «задержка» (после старта или восстановления)
    xPlcStart    : BOOL;            // задержка — после старта ПЛК (tPlcStart), иначе tPwrRestart
    xSeq         : BOOL;            // состояние «последовательный пуск»
    uiStep       : UINT;            // разрешено запросов на шаге
    xConfirmed   : BOOL;            // пуски шага подтверждены (отсчёт tSeqStep)
    fbDelay      : PL.FB_Delay;     // задержка tPlcStart / tPwrRestart
    fbStepWait   : PL.FB_Delay;     // tSeqStep после подтверждения пусков шага
    fbStepTimeout : PL.FB_Delay;    // пуск шага не подтвердился за STN_SEQ_START_TIMEOUT
END_VAR
VAR_TEMP
    xAdvance  : BOOL;               // перейти к следующему шагу
    tRemain   : TIME;               // до следующего шага
    udiRemain : UDINT;              // то же, с (вверх)
END_VAR
