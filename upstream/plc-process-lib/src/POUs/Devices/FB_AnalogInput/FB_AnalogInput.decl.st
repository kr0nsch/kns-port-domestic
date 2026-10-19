// Назначение: аналоговый вход. Сигнал 4–20 мА, нормированный 0–1, инженерные единицы или отсчёты
//             канала → значение в инженерных единицах: достоверность по NAMUR NE 43 с
//             подтверждением tFailDelay и удержанием последнего хорошего значения на время
//             подтверждения, корень с отсечкой малых значений, фильтр первого порядка по реальному
//             шагу времени, уставки HH/H/L/LL (FB_LimitMonitor), подмена значения с ограничением по
//             времени, шесть слотов тревог. Режимы: Auto — измерение, Manual — подмена,
//             OutOfService; Local нет. Наследует FB_DeviceBase: тело — нормативный порядок цикла,
//             шаги обработки сигнала — защищённые методы.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_AnalogInput.md
FUNCTION_BLOCK FB_AnalogInput EXTENDS FB_DeviceBase
VAR_INPUT
    rIn                  : REAL;     // значение канала; смысл — по stCfg.eInput
    xChannelFault        : BOOL;     // диагностика модуля или ошибка обмена (для значений по Modbus)
    xSuppressLimitAlarms : BOOL;     // подавить тревоги уставок по условию (флаги уставок считаются)
END_VAR
VAR_IN_OUT
    stCmd : ST_AnalogInputCmd;       // команды HMI/SCADA (GVL_Hmi.st<TAG>Cmd)
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_AnalogInputCfg;       // параметры (GVL_Persist.st<TAG>Cfg), только чтение
END_VAR
VAR_OUTPUT
    rValue_eu  : REAL;               // значение для логики, инж. ед.
    rValue_pct : REAL;               // значение, % шкалы
    xValid     : BOOL;               // значение пригодно для управления
    xHH        : BOOL;               // верхняя аварийная уставка (после гистерезиса и задержек)
    xH         : BOOL;               // верхняя предупредительная уставка
    xL         : BOOL;               // нижняя предупредительная уставка
    xLL        : BOOL;               // нижняя аварийная уставка
    stSts      : ST_AnalogInputSts;  // состояние для HMI/SCADA
END_VAR
VAR
    stCfgLkg  : ST_AnalogInputCfg;                       // последняя корректная конфигурация (LKG)
    afbLimit  : ARRAY[0..3] OF FB_LimitMonitor;          // уставки, индекс E_AiAlarm.HH, H, L, LL
    fbFail    : FB_Delay;                                // подтверждение отказа сигнала и возврата
    fbOor     : FB_Delay;                                // подтверждение выхода за диапазон и возврата
    fbSubst   : FB_Delay;                                // длительность подмены (tSubstMax)
    eSignal   : E_AiSignalState := E_AiSignalState.Good; // мгновенная классификация сигнала
    xRawFail  : BOOL;                                    // мгновенный отказ сигнала (до подтверждения)
    xFail     : BOOL;                                    // отказ сигнала подтверждён
    xOor      : BOOL;                                    // выход за диапазон подтверждён
    xValueBad : BOOL;                                    // измеренного значения нет: отказ подтверждён
                                                         // или хорошего значения ещё не было
    lrFlt     : LREAL;                                   // состояние фильтра, инж. ед.
    xFltInit  : BOOL := TRUE;                            // фильтр начнётся с текущего значения
    rGood_eu  : REAL;                                    // последнее хорошее значение, инж. ед.
    xHaveGood : BOOL;                                    // хорошее значение было после старта ПЛК или
                                                         // после возврата контроля (OutOfService, Cfg)
    xLowCut   : BOOL;                                    // сработала отсечка малых значений
    xClamped  : BOOL;                                    // значение ограничено шкалой
END_VAR
VAR_TEMP
    eRes       : E_CmdResult;        // результат ProcessMode
    xRawOor    : BOOL;               // мгновенный выход за диапазон (до подтверждения)
    xSupervise : BOOL;               // контроль сигнала: корректная Cfg была, не OutOfService
    xLimOff    : BOOL;               // флаги уставок снять сразу
    xLimSupp   : BOOL;               // подавление тревог уставок
    wLowBits   : WORD;               // младший байт wStatus
    eDevSt     : E_Ne107Status;      // вклад логики устройства в NE 107
END_VAR
