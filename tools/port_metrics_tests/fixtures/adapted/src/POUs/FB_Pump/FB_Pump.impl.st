// PORT: [oop] вызов базы через экземпляр вместо SUPER^
fbBase();
tonDelay(IN := xStart, PT := stCfg.tStartDelay);
xRunning := tonDelay.Q AND NOT fbBase.xFault; // PORT: доступ к полю базы через экземпляр (наследование)
IF xRunning THEN
    Start();
ELSE
    Stop();
END_IF
