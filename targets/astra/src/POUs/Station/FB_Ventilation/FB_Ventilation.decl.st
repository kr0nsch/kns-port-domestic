// Назначение: вентилятор павильона В1 (04 §17): работает при газе выше H, открытой двери или
//             температуре выше H и ещё tV1Overrun после снятия всех условий; пожар — стоп и
//             блокировка V1_ILK_FIRE (действует в Auto и Manual устройства).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 6.10; docs/04_algorithms.md, раздел 17
FUNCTION_BLOCK FB_Ventilation
VAR_INPUT
    xGasHigh  : BOOL;               // fbAT401.xH OR fbAT402.xH
    xDoorOpen : BOOL;               // fbZS404.xValue
    xTempHigh : BOOL;               // fbTT403.xH
    xFire     : BOOL;               // fbYS405.xValue
    itfTime   : PL.I_TimeSource;
END_VAR
VAR_IN_OUT CONSTANT
    stCfg : ST_StationCfg;          // tV1Overrun
END_VAR
VAR_OUTPUT
    xRun       : BOOL;              // → fbV1.xAutoRun
    wInterlock : WORD;              // → fbV1.wInterlock (V1_ILK_FIRE)
END_VAR
VAR
    fbOverrun : PL.FB_Delay;        // выбег tV1Overrun после снятия условий
END_VAR
