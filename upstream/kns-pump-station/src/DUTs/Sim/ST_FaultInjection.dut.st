// Назначение: инъекции отказов модели (GVL_Sim.stFaultInj). Пишут HMI (экран «Имитация») и
//             сценарии ПМИ; действуют только при GVL_Sim.xSimulation. Индекс насоса 1…3 = Н1…Н3,
//             индекс датчика — SIM_AI_*. Имена полей использует таблица 06 §5.4 и экран 08.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.3; docs/06_PMI.md, раздел 5.4
{attribute 'qualified_only'}
TYPE ST_FaultInjection :
STRUCT
    // авария ПЧ: реле FLT, бит STW.2, код SIM_VFD_FCODE_EXT; снимается сбросом ПЧ после снятия инъекции
    axVfdFault      : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;
    // реле «Работа» не замыкается (ПЧ работает) → FailToStart / FeedbackLost
    axNoFeedback    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;
    // реле «Работа» залипло в TRUE → FailToStop / UncommandedRun
    axFeedbackStuck : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;
    axAirLock       : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;  // сухой ход насоса: подача 0, ток мал → недогрузка
    axClog          : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;  // засор: подача −60 %, ток ×1,3 к току без засора
    axOverheat      : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;  // TS1n2 размыкается и разрывает цепь аварии ПЧ
    axLeak          : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;  // MS1n3
    // нет ответа ПЧ: регистры замирают, xMbOk = FALSE; через SIM_VFD_WATCHDOG — 50 Гц (04 §12);
    // все три — потеря линии RS485-1
    axVfdCommLoss   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;
    axLocal         : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;  // переключатель HS1n4 в «Местное»
    axLocalRun      : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;  // пуск с местного поста (в «Местном»)
    // индексы SIM_AI_*: LT101, PT201, FT202, AT401, AT402
    aeAiFault       : ARRAY[1..GVL_Const.SIM_AI_COUNT] OF E_SimAiFault;
    arAiForced_mA   : ARRAY[1..GVL_Const.SIM_AI_COUNT] OF REAL;  // ток при Forced
    eLs102Stuck     : E_SimFloatStuck;
    eLs103Stuck     : E_SimFloatStuck;
    xPowerLoss      : BOOL;                 // нет напряжения на вводе: ES301 = 0, ПЧ обесточены, ИБП на батареях
    xUpsFault       : BOOL;                 // YS303
    xTempCommLoss   : BOOL;                 // TT403 (RS485-2) не отвечает
    xFanFault       : BOOL;                 // V1_FLT
    xFanNoFeedback  : BOOL;                 // V1_RFB не приходит при работающем вентиляторе (04 §20, вопрос 10)
    xValveChamberFlood : BOOL;              // LS203
    xFire           : BOOL;                 // YS405
    // концентрации газов вместо фоновых из stSimCfg; < 0 — фон (по умолчанию и после xClearFaults)
    rH2S_mgm3       : REAL := -1.0;
    rCh4_pctLel     : REAL := -1.0;
END_STRUCT
END_TYPE
