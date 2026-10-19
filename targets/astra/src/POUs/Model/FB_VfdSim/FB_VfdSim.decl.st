// Назначение: модель ПЧ насоса по условной карте (ARCHITECTURE, раздел 12). Частота идёт к заданию
//             FREF / 100 Гц с ускорением 50 Гц / tAccel, пока есть «Пуск» (провод xP10n_RUN; в «Местном» —
//             пуск с местного поста на частоте SIM_VFD_LOCAL_FREQ_HZ), иначе тормозит тем же темпом; реле
//             «Работа» — пока выход инвертора активен. Авария (инъекция или перегрев TS1n2) — выбег (частота 0),
//             реле «Авария», бит STW.2, код; сброс — фронтом бита CTW.2 после снятия причины. Нет питания —
//             ПЧ обесточен (регистры 0, связи нет), после возврата — tBoot до готовности. Потеря связи —
//             регистры чтения замирают, записи не доходят (ПЧ помнит последние CTW и FREF); через
//             SIM_VFD_WATCHDOG без запросов сторожевой таймер ПЧ переводит задание на SIM_VFD_WATCHDOG_FREQ_HZ
//             (50 Гц), пуск и стоп — по проводу (04 §12, PMI-28, PMI-29); после восстановления связи ПЧ снова
//             следует FREF. Время — PL.I_TimeSource (шаг рампы и выдержки), «время назад» — шаг 0.
// Автор:      kr0nsch
// Версия:     0.1.1
// Документ:   docs/DESIGN.md, раздел 11.2; docs/04_algorithms.md, раздел 12
FUNCTION_BLOCK FB_VfdSim
VAR_INPUT
    xRunCmd         : BOOL;         // провод «Пуск» от ПЛК (GVL_IO.xP10n_RUN)
    wCtw            : WORD;         // слово управления, FC16 адрес 0 (GVL_IO.wP10n_CTW)
    uiFref          : UINT;         // задание частоты, 0,01 Гц, FC16 адрес 1 (GVL_IO.uiP10n_FREF)
    xPowerOk        : BOOL := TRUE; // питание силовой части и платы управления (NOT stFaultInj.xPowerLoss)
    xFaultInj       : BOOL;         // stFaultInj.axVfdFault[i]
    xOverheat       : BOOL;         // stFaultInj.axOverheat[i]: TS1n2 разрывает цепь аварии ПЧ
    xCommLoss       : BOOL;         // stFaultInj.axVfdCommLoss[i]
    xLocal          : BOOL;         // stFaultInj.axLocal[i]: HS1n4 в «Местное»
    xLocalRun       : BOOL;         // stFaultInj.axLocalRun[i]: пуск с местного поста
    xNoFeedback     : BOOL;         // stFaultInj.axNoFeedback[i]: реле «Работа» не замыкается
    xFeedbackStuck  : BOOL;         // stFaultInj.axFeedbackStuck[i]: реле «Работа» залипло
    rMotorCurrent_A : REAL;         // ток двигателя по гидравлике (прошлый шаг модели) — регистр 102
    tAccel          : TIME := T#10S;   // разгон 0 → 50 Гц (stSimCfg.tVfdAccel); T#0S — без рампы
    tBoot           : TIME := T#5S;    // готовность после подачи питания (stSimCfg.tVfdBoot)
    itfTime         : PL.I_TimeSource; // источник времени; 0 — системное
END_VAR
VAR_OUTPUT
    rFreq_Hz      : REAL;           // выходная частота инвертора (истинная)
    rRef_Hz       : REAL;           // действующее задание
    xOutputActive : BOOL;           // выход инвертора активен (пуск или торможение)
    xReady        : BOOL;           // готов к пуску: питание, загрузка, нет аварии
    xFaulted      : BOOL;           // авария зафиксирована
    xWatchdog     : BOOL;           // сработал сторожевой таймер связи: задание = SIM_VFD_WATCHDOG_FREQ_HZ
    xCommOk       : BOOL;           // ПЧ отвечает мастеру (GVL_IO.xMbOk_RS485_1_Sn)
    xRelayRun     : BOOL;           // реле «Работа» (GVL_IO.xP10n_RFB) с инъекциями
    xRelayFault   : BOOL;           // реле «Авария» (GVL_IO.xP10n_FLT)
    wStw          : WORD;           // регистр 100: слово состояния
    uiFact        : UINT;           // регистр 101: частота, 0,01 Гц
    uiCurrent     : UINT;           // регистр 102: ток, 0,1 А
    uiFcode       : UINT;           // регистр 103: код последней аварии
END_VAR
VAR
    fbSysTime   : PL.FB_SystemTime; // запасной источник времени
    itfTimeAct  : PL.I_TimeSource;  // действующий источник
    fbBoot      : PL.FB_Delay;      // загрузка после подачи питания
    fbWatchdog  : PL.FB_Delay;      // сторожевой таймер связи
    xInit       : BOOL;             // первый вызов выполнен
    ltLast      : LTIME;            // время прошлого вызова
    ltNow       : LTIME;            // время этого вызова
    lrDt_s      : LREAL;            // шаг рампы
    xOn         : BOOL;             // ПЧ включён и загружен
    wCtwRx      : WORD;             // последнее принятое слово управления
    uiFrefRx    : UINT;             // последнее принятое задание
    xResetPrev  : BOOL;             // бит сброса прошлого вызова (фронт)
    xResetBit   : BOOL;             // бит сброса в принятом слове управления
    uiLastFcode : UINT;             // код последней аварии
    xRunReq     : BOOL;             // действующая команда пуска (провод или местный пост)
    rRate_Hzps  : REAL;             // темп разгона и торможения
    lrAccel_s   : LREAL;            // tAccel, с
    xResetReq   : BOOL;             // запрос ResetDrive: выполнить в ближайшем вызове тела
END_VAR
