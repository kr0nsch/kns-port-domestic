// Назначение: ПИД-регулятор в идеальной форме (Kp, Ti, Td): D по измерению с фильтром первого
//             порядка, anti-windup обратным расчётом с постоянной слежения Tt (по своему выходу
//             или по фактическому выходу механизма rOutAct_pct), пределы и ограничение скорости
//             выхода, Manual и слежение (xTrack) с безударным переходом, внешнее или операторское
//             задание с рампой, прямое и обратное действие, зона нечувствительности, расчёт по
//             реальному dt источника времени и период расчёта tSample, реакция на недостоверную PV.
//             Внутреннее состояние (I, D, PV прошлого шага, задание после рампы, выход) — LREAL.
//             Режимы Auto, Manual, OutOfService (Local нет); одна тревога PvInvalid.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_PID.md
FUNCTION_BLOCK FB_PID EXTENDS FB_DeviceBase
VAR_INPUT
    rPv_eu      : REAL;              // регулируемая величина, инж. ед.
    xPvValid    : BOOL;              // PV достоверна; по умолчанию FALSE — забытая привязка видна сразу
    xSpExt      : BOOL;              // задание от логики (каскад, график), а не от оператора
    rSpExt_eu   : REAL;              // внешнее задание, инж. ед.
    xTrack      : BOOL;              // слежение: выход := rTrack_pct (исполнительный механизм не в Auto)
    rTrack_pct  : REAL;              // значение для слежения, %
    rOutAct_pct : REAL;              // фактический выход механизма, % (при stCfg.xUseOutAct)
END_VAR
VAR_IN_OUT
    stCmd    : ST_PidCmd;            // команды HMI/SCADA; ФБ пишет слежение rSp_eu, rManualOut_pct
    stRetain : ST_DeviceRetain;      // используются eRemoteMode и xOutOfService
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_PidCfg;               // параметры (Persistent Variables приложения)
END_VAR
VAR_OUTPUT
    rOut_pct : REAL;                 // выход, %
    xSatHigh : BOOL;                 // выход на верхнем пределе rOutMax_pct
    xSatLow  : BOOL;                 // выход на нижнем пределе rOutMin_pct
    stSts    : ST_PidSts;            // состояние для HMI/SCADA
END_VAR
VAR
    stCfgLkg      : ST_PidCfg;       // последняя корректная конфигурация (LKG, нормативно)
    // --- состояние алгоритма (LREAL: малые приращения интегратора не теряются рядом с 50 %) ---
    lrOut_pct     : LREAL;           // выход u (он же u прошлого шага для ограничения скорости)
    lrI_pct       : LREAL;           // интегральная составляющая (после обновления этого шага)
    lrP_pct       : LREAL;           // пропорциональная составляющая последнего расчёта
    lrD_pct       : LREAL;           // дифференциальная составляющая последнего расчёта
    lrV_pct       : LREAL;           // v = P + I + D до ограничения, последний расчёт
    lrErr_pct     : LREAL;           // ошибка e' после зоны нечувствительности, % диапазона PV
    lrPvPrev_eu   : LREAL;           // PV прошлого расчёта (D по измерению)
    lrSp_eu       : LREAL;           // действующее задание (после рампы)
    lrSpTarget_eu : LREAL;           // цель задания после пределов (до рампы)
    lrDtCalc_s    : LREAL;           // dt последнего расчёта, с; 0 — шаг инициализации
    ltLastCalc    : LTIME;           // время последнего расчёта
    xCalcInit     : BOOL := TRUE;    // следующий расчёт — шаг инициализации (старт, PV вернулась, OOS)
    xFirstCalc    : BOOL := TRUE;    // расчёта ещё не было (первый расчёт ставит бит DT_GAP)
    xSpInit       : BOOL := TRUE;    // рампа задания не начата: первый расчёт берёт цель сразу
    // --- признаки последнего вызова (карта битов) ---
    xPvOk         : BOOL;            // xPvValid AND PV конечна
    xDtGap        : BOOL;            // разрыв времени: шаг инициализации этого вызова
    xSpInvalid    : BOOL;            // цель задания не конечна, удерживается прежняя
    xInDeadband   : BOOL;            // ошибка в зоне нечувствительности (последний расчёт)
    xOutRateLim   : BOOL;            // выход ограничен по скорости (последний расчёт в Auto)
    xTrackAct     : BOOL;            // выход следует за rTrack_pct
    xPvShed       : BOOL;            // ФБ сам перевёл контур в Manual по отказу PV (ShedToManual)
END_VAR
VAR_TEMP
    xAutoReq      : BOOL;            // в этом вызове запрошен Auto
    xHigherReq    : BOOL;            // запрошен Manual или OutOfService (старше Auto)
    eRes          : E_CmdResult;     // результат ProcessMode
    xSpTrack      : BOOL;            // задание следует за PV (Manual, xSpTrackPv)
    rSpRaw_eu     : REAL;            // цель задания до пределов
    xCalc         : BOOL;            // в этом вызове выполняется расчёт
    xInitStep     : BOOL;            // расчёт — шаг инициализации
    ltElapsed     : LTIME;           // время от последнего расчёта
    lrDt_s        : LREAL;           // шаг расчёта, с
    xPvFault      : BOOL;            // PV негодна в Auto без слежения: Failure
    eDevSt        : E_Ne107Status;   // вклад логики в NE 107
END_VAR
