// Назначение: поддержание уровня ПИД LIC101 — число насосов и подключение подпорного по нагрузке
//             (04 §7.2), готовность ПИД (04 §7.4) с выдержкой STN_PID_RECOVER после восстановления
//             связи с ПЧ (04 §12), слежение ПИД за заданием ведущего, когда ПИД не управляет (04 §7.3).
//             Задание ПИД ФБ не считает: оно внешнее (stCfgLkg.rLevelSp_m, PRG_Station).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.4; docs/04_algorithms.md, разделы 7, 12
FUNCTION_BLOCK FB_LevelControlPid
VAR_INPUT
    xEnable     : BOOL;             // eControlAct = LevelPid
    rLevel_m    : REAL;
    xLevelValid : BOOL;
    rPidOut_pct : REAL;             // GVL_Station.fbLIC101.rOut_pct (прошлый цикл)
    ePidMode    : PL.E_DeviceMode;  // GVL_Station.fbLIC101.Mode
    aitfPump    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF PL.I_MotorVfd;
    axCommOk    : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;   // нет MOT_WRN_COMM_LOSS
    uiLead      : UINT;             // ведущий (FB_PumpRotation, прошлый цикл); 0 — нет
    xInit       : BOOL;
    uiInitPumps : UINT;
    itfTime     : PL.I_TimeSource;
END_VAR
// PORT: [types] проверить в Astra.IDE — VAR_IN_OUT CONSTANT (C13)
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // rLvlStop_m, rLvlStartLead_m, rLvlStartAssist_m, tLvlConfirm,
                                    // rAssistOn_pct, tAssistOn, rAssistOff_pct, tAssistOff, uiDutyMax
END_VAR
VAR_OUTPUT
    uiRequired   : UINT;
    xPidReady    : BOOL;            // 04 §7.4; после восстановления связи — через STN_PID_RECOVER
    xPidControls : BOOL;            // xEnable AND ведущий SpeedAutoActive AND связь ведущего есть
    xTrack       : BOOL;            // → fbLIC101.xTrack (= NOT xPidControls)
    rTrack_pct   : REAL;            // → fbLIC101.rTrack_pct и rOutAct_pct: SpeedRef ведущего (0 — нет)
END_VAR
VAR
    uiPumps        : UINT;          // состояние: 0, 1, 2 насоса
    fbStartLead    : PL.FB_Delay;   // 0 → 1: уровень >= rLvlStartLead_m (tLvlConfirm)
    fbAssistOnOut  : PL.FB_Delay;   // 1 → 2: выход ПИД >= rAssistOn_pct (tAssistOn)
    fbAssistOnLvl  : PL.FB_Delay;   // 1 → 2: уровень >= rLvlStartAssist_m (tLvlConfirm)
    fbAssistOff    : PL.FB_Delay;   // 2 → 1: выход ПИД <= rAssistOff_pct и уровень < rLvlStartAssist_m (tAssistOff)
    fbStopAll      : PL.FB_Delay;   // 1, 2 → 0: уровень <= rLvlStop_m (tLvlConfirm)
    fbCommRecover  : PL.FB_Delay;   // насос со связью есть: снятие сразу, возврат через STN_PID_RECOVER
    xFirstCall     : BOOL := TRUE;  // первый вызов: связь без выдержки возврата
END_VAR
VAR_TEMP
    uiMax          : UINT;          // MIN(STN_DUTY_MAX, uiDutyMax)
    uiPump         : UINT;          // номер насоса
    xAnyRunning    : BOOL;          // работает насос в Auto
    xCommRunning   : BOOL;          // работает насос в Auto со связью
    xCommAvailable : BOOL;          // доступен насос со связью (когда насосы стоят)
    xAnyAvailable  : BOOL;          // доступен хотя бы один насос
    xLeadValid     : BOOL;          // номер ведущего 1…STN_PUMP_COUNT и интерфейс задан
    xCommPart      : BOOL;          // есть насос со связью (условие готовности по связи)
    xCommBlock     : BOOL;          // насосы есть, но связи нет ни у одного: потеря связи
END_VAR
