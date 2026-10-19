// Инициализация экземпляра
METHOD FB_init : BOOL
VAR_INPUT
    bInitRetains : BOOL;    // TRUE — инициализировать RETAIN
    bInCopyCode : BOOL;     // TRUE — экземпляр копируется при онлайн-изменении
END_VAR
