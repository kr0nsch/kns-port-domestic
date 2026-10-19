// Назначение: режим станции «Автомат»/«Ручной» и выбранный способ регулирования (04 §3).
//             Санитизирует энергонезависимые eMode и eMethod сравнениями; при смене режима
//             запрашивает режим насосам (Ручной → Автомат: Auto насосам в Manual и Local, кроме
//             OutOfService; Автомат → Ручной: Manual насосам в Auto и Local) и даёт импульсы для
//             безударного перехода. xSetManual старше xSetAuto, xSetStepped старше xSetLevelPid.
//             События 101001…101004.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.1; docs/04_algorithms.md, раздел 3
FUNCTION_BLOCK FB_StationMode
VAR_INPUT
    xSetAuto     : BOOL;
    xSetManual   : BOOL;
    xSetStepped  : BOOL;
    xSetLevelPid : BOOL;
    aitfPump     : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF PL.I_MotorVfd;
    itfEvents    : I_StationEventSink;
END_VAR
VAR_IN_OUT
    stRetain : ST_StationRetain;            // eMode, eMethod
END_VAR
VAR_OUTPUT
    eMode          : E_StationMode;
    eMethod        : E_ControlMethod;
    xEnteredAuto   : BOOL;                  // один вызов: переход в «Автомат» и первый вызов в «Автомате»
    xEnteredManual : BOOL;
    xMethodChanged : BOOL;
    uiCmdCount     : UINT;                  // обработано команд в этом вызове
    eCmdResult     : PL.E_CmdResult;        // результат последней (Accepted)
END_VAR
VAR
    xFirstCall : BOOL := TRUE;              // первый вызов: импульс входа в режим из retain
END_VAR
VAR_TEMP
    uiPump     : UINT;                      // номер насоса
    eModeNew   : E_StationMode;             // режим после команд этого вызова
    eMethodNew : E_ControlMethod;           // способ после команд этого вызова
    ePumpMode  : PL.E_DeviceMode;           // режим насоса
END_VAR
