// Тревога с номером udiId среди источников; 0 — не найдена
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PRIVATE (C3)
METHOD PRIVATE FindAlarm : PL.I_Alarm
VAR_INPUT
    udiId : UDINT;
END_VAR
VAR
    uiSrc  : UINT;
    uiK    : UINT;
    itfSrc   : PL.I_AlarmSource;   // источник
    itfAlm : PL.I_Alarm;
END_VAR
