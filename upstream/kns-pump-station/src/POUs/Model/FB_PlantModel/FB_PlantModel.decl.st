// Назначение: модель объекта КНС-1 без обращений к глобальным переменным (интеграционные тесты
//             вызывают её так же, как PRG_PlantModel). За вызов: команды модели (импульсы stCmd
//             сбрасываются здесь, xClearFaults обнуляет stFault), ПЧ насосов, затем подшагами не длиннее
//             SIM_DT_SUBSTEP — время суток, приток (профиль + ливни или постоянный), рабочая точка насосов
//             и баланс резервуара; затем датчики 4–20 мА с инъекциями, контакты, кнопки, регистры ПЧ и
//             обмен Modbus в stIo, состояние в stSts, счётчик изменений инъекций udiFaultSeq. Шаг времени
//             за вызов — от itfTime (часы модели с ускорением), не больше SIM_DT_MAX; «время назад» —
//             шаг 0. Пишет только входы ПЛК (stIo), выходы ПЛК читает со входов axRun, awCtw, auiFref, xV1Run.
// Автор:      kr0nsch
// Версия:     0.1.1
// Документ:   docs/DESIGN.md, раздел 11; docs/ARCHITECTURE.md, раздел 4
FUNCTION_BLOCK FB_PlantModel
VAR_INPUT
    itfTime : PL.I_TimeSource;                                  // часы модели (GVL_Time.fbClockModel); 0 — системные
    axRun   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;       // GVL_IO.xP10n_RUN: провод «Пуск» ПЧ
    awCtw   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF WORD;       // GVL_IO.wP10n_CTW
    auiFref : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF UINT;       // GVL_IO.uiP10n_FREF
    xV1Run  : BOOL;                                             // GVL_IO.xV1_RUN
    rTimeScaleAct : REAL := 1.0;                                // действующее ускорение часов (для stSts)
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_SimCfg;                  // параметры модели (GVL_Sim.stSimCfg)
END_VAR
VAR_IN_OUT
    stCmd   : ST_SimCmd;                // команды модели (GVL_Sim.stSimCmd); импульсы сбрасываются здесь
    stFault : ST_FaultInjection;        // инъекции (GVL_Sim.stFaultInj); xClearFaults обнуляет
END_VAR
VAR_OUTPUT
    stIo  : ST_PlantIo;                 // входы ПЛК → GVL_IO
    stSts : ST_SimSts;                  // состояние модели → GVL_Sim.stSimSts
END_VAR
VAR
    fbSysTime   : PL.FB_SystemTime;     // запасной источник времени
    itfTimeAct  : PL.I_TimeSource;      // действующий источник
    fbInflow    : FB_InflowProfile;
    fbStorms    : FB_StormGenerator;
    fbTank      : FB_TankModel;
    fbHydraulic : FB_HydraulicSolver;
    afbVfd      : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF FB_VfdSim;
    afbAi       : ARRAY[1..GVL_Const.SIM_AI_COUNT] OF FB_AnalogSensorSim;   // индексы SIM_AI_*
    fbHs501     : PL.FB_Delay;          // длительность нажатия HS501
    fbHs502     : PL.FB_Delay;          // длительность нажатия HS502
    fbV1Fb      : PL.FB_Delay;          // блок-контакт пускателя В1 после команды
    xHs501Pressed : BOOL;               // кнопка HS501 нажата моделью
    xHs502Pressed : BOOL;
    stFaultPrev : ST_FaultInjection;    // инъекции прошлого вызова (счётчик изменений)
    stFaultNone : ST_FaultInjection;    // все инъекции сняты (значения по умолчанию типа)
    udiFaultSeq : UDINT;                // изменений инъекций с запуска
    xInit       : BOOL;                 // первый вызов выполнен
    ltNow       : LTIME;                // время этого вызова
    ltLast      : LTIME;                // время прошлого вызова
    ltDt        : LTIME;                // шаг за вызов
    lrDt_s      : LREAL;
    lrSub_s     : LREAL;                // подшаг
    uiSubsteps  : UINT;                 // подшагов за вызов
    uiSub       : UINT;
    uiPump      : UINT;
    uiAi        : UINT;
    lrClock_h   : LREAL;                // часы модели: ч от полуночи суток 0
    lrSimTime_s : LREAL;                // время модели с запуска
    rTod_h      : REAL;                 // время суток
    rInflow_m3h : REAL;                 // действующий приток
    arSpeed     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF REAL;   // s = f / 50 Гц
    arAiValue   : ARRAY[1..GVL_Const.SIM_AI_COUNT] OF REAL;     // измеряемые величины датчиков
    arAiRange   : ARRAY[1..GVL_Const.SIM_AI_COUNT] OF REAL;     // верх шкалы датчиков (низ — 0)
    rTT403Hold  : REAL;                 // последнее значение TT403, принятое мастером RS485-2
END_VAR
