// Назначение: дискретный вход: инверсия (НЗ-контакт), задержки включения и отключения (FB_Delay),
//             подмена значения с ограничением по времени, отказ канала со значением по eFailValue,
//             тревога по состоянию и тревога отказа канала. Режимы: Auto — измерение, Manual —
//             подмена, OutOfService; Local нет. Наследует FB_DeviceBase: тело — нормативный порядок
//             цикла.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_DigitalInput.md
FUNCTION_BLOCK FB_DigitalInput EXTENDS FB_DeviceBase
VAR_INPUT
    xIn           : BOOL;            // сигнал канала
    xChannelFault : BOOL;            // диагностика обрыва/КЗ (NAMUR-датчики, модуль), ошибка обмена
END_VAR
VAR_IN_OUT
    stCmd : ST_DigitalInputCmd;      // команды HMI/SCADA (GVL_Hmi.st<TAG>Cmd)
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_DigitalInputCfg;      // параметры (GVL_Persist.st<TAG>Cfg), только чтение
END_VAR
VAR_OUTPUT
    xValue : BOOL;                   // значение для логики
    xValid : BOOL;                   // нет отказа канала (или подмена), Cfg была корректна, не OOS
    stSts  : ST_DigitalInputSts;     // состояние для HMI/SCADA
END_VAR
VAR
    stCfgLkg   : ST_DigitalInputCfg; // последняя корректная конфигурация (LKG)
    fbDebounce : FB_Delay;           // задержки включения и отключения
    fbSubst    : FB_Delay;           // длительность подмены (tSubstMax)
    xGood      : BOOL;               // значение после задержек; при отказе канала — значение отказа (DI-2)
    xDelayInit : BOOL := TRUE;       // задержки ещё не предустановлены (до первого вызова с корректной Cfg)
END_VAR
VAR_TEMP
    eRes      : E_CmdResult;         // результат ProcessMode
    xRaw      : BOOL;                // сигнал после инверсии, до задержек
    xFaultAct : BOOL;                // отказ канала учитывается (не OutOfService)
    xAlmCond  : BOOL;                // условие тревоги State
    rAlmValue : REAL;                // значение для событий тревог: 0.0 / 1.0
    wLowBits  : WORD;                // младший байт wStatus
    eDevSt    : E_Ne107Status;       // вклад логики устройства в NE 107
END_VAR
