// Назначение: защиты одного насоса (04 §10.3, 10.4): недогрузка по току («сухой ход насоса» —
//             работает на частоте не ниже rUnderloadSpeed_pct при токе ниже rUnderload_A дольше
//             tUnderload) с фиксацией до сброса насоса; перегрев обмотки — блокировка, пока сигнал
//             активен. Ток недостоверен — контроля нет; rUnderload_A = 0 — контроль выключен.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.8; docs/04_algorithms.md, разделы 10.3, 10.4
FUNCTION_BLOCK FB_PumpProtection
VAR_INPUT
    xRunning      : BOOL;           // aitfPump[i].Running
    rSpeedAct_pct : REAL;           // aitfPump[i].SpeedAct
    rCurrent_A    : REAL;           // fbIT1n1.rValue_eu
    xCurrentValid : BOOL;           // fbIT1n1.xValid (нет связи — контроля нет)
    xOverheat     : BOOL;           // fbTS1n2.xValue
    xReset        : BOOL;           // импульс: GVL_Hmi.stP10nCmd.stCommon.xReset, HS501, xResetAll
    itfTime       : PL.I_TimeSource;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // rUnderload_A (0 — выкл.), rUnderloadSpeed_pct, tUnderload
END_VAR
VAR_OUTPUT
    wInterlock       : WORD;        // KNS_ILK_UNDERLOAD (фиксация) OR KNS_ILK_OVERHEAT (пока сигнал)
    xUnderloadTrip   : BOOL;        // KNS1.ULn
    xUnderloadTiming : BOOL;
END_VAR
VAR
    fbUnderload : PL.FB_Delay;      // выдержка tUnderload
END_VAR
VAR_TEMP
    xCond : BOOL;                   // условие недогрузки до выдержки
END_VAR
