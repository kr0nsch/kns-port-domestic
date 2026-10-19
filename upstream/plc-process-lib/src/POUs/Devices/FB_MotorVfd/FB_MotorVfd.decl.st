// Назначение: двигатель с преобразователем частоты (I_MotorVfd): всё от FB_Motor плюс задание
//             скорости 0–100 % с пределами и ограничением скорости изменения, обратная связь по
//             скорости и контроль рассогласования, отказ связи с ПЧ (нефиксируемый или только
//             предупреждение), авария и готовность ПЧ из слова состояния. Тело: точки расширения
//             FB_Motor, затем тело FB_Motor через SUPER^(...) со всеми VAR_IN_OUT, затем задание
//             скорости и слежение. Карт регистров ПЧ нет: сигналы разбирает адаптер приложения.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_MotorVfd.md
FUNCTION_BLOCK FB_MotorVfd EXTENDS FB_Motor IMPLEMENTS I_MotorVfd
VAR_INPUT
    rSpeedSpAuto_pct : REAL;           // задание скорости от автоматики (ПИД), %
    xCommOk          : BOOL := TRUE;   // обмен с ПЧ исправен (драйвер Modbus / диагностика)
    xVfdRunning      : BOOL;           // ПЧ в работе (слово состояния)
    xVfdReady        : BOOL := TRUE;   // ПЧ готов к пуску (слово состояния)
    xVfdFault        : BOOL;           // авария ПЧ (слово состояния)
    rSpeedAct_pct    : REAL;           // фактическая скорость, % от номинальной
END_VAR
VAR_OUTPUT
    rSpeedRef_pct    : REAL;           // задание на ПЧ, %; 0 без команды работы
    xSpeedAutoActive : BOOL;           // Auto AND Running AND wFault = 0: ПИД не в слежении
END_VAR
VAR
    // нормативные имена (контракт 14.1); все внутренние имена содержат «Vfd» (L2)
    fbVfdCommLoss     : FB_Delay;      // фильтр потери связи tCommLoss
    fbVfdPowerUp      : FB_Delay;      // питание есть дольше VFD_POWER_UP_DELAY: ПЧ загрузился, связь контролируется
    fbVfdSpeedDev     : FB_Delay;      // задержка рассогласования tSpeedDev
    xVfdCommValid     : BOOL;          // xCommOk AND F_IsFinite(rSpeedAct_pct)
    rVfdSpeedAct_pct  : REAL;          // rSpeedAct_pct последнего вызова (SpeedAct)
    // реализация
    stVfdCfgUse       : ST_VfdCfg;     // параметры ПЧ для точек расширения этого вызова (LKG)
    xVfdRampDone      : BOOL;          // задание прошлого вызова дошло до цели
    xVfdSpeedDevCond  : BOOL;          // условие рассогласования до задержки
    xVfdCommWarn      : BOOL;          // потеря связи без отказа (xCommLossIsFault = FALSE)
    rVfdTarget_pct    : REAL;          // цель задания по режиму
    rVfdTargetLim_pct : REAL;          // цель в пределах rSpeedMin_pct…rSpeedMax_pct
    xVfdTargetOk      : BOOL;          // цель конечна
    lrVfdDt_s         : LREAL;         // шаг времени вызова, с
    lrVfdRef_pct      : LREAL;         // состояние рампы задания (LREAL: медленная рампа при коротком цикле, VFD-13)
    xVfdRunCmdPrev    : BOOL;          // xRunCmd прошлого вызова (подхват)
    xVfdStartPending  : BOOL;          // предустановка пуска (rSpeedMin) ждёт связи (VFD-10)
    xVfdPickPending   : BOOL;          // предустановка подхвата (фактическая скорость) ждёт связи (VFD-09)
    xVfdNoPowerComm   : BOOL;          // связи нет, но не контролируется: нет питания или ПЧ загружается (VFD-12)
END_VAR
