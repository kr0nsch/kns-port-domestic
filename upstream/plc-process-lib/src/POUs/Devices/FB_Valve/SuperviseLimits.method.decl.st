// Шаг 6.3–6.4: внешняя авария, «оба концевика», уход с концевика (фильтры tLimitFilter).
// Шаг тела FB_Valve; внутренний: PROTECTED (правило L5 контракта), имя зарезервировано для наследников
METHOD PROTECTED SuperviseLimits
VAR
    xLeftEnd : BOOL;   // в Open/Closed, подтверждённом концевиком, он пропал
END_VAR
