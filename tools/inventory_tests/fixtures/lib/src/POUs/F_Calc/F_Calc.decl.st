// Назначение: операторы LTIME, динамическая память, запросы интерфейсов
FUNCTION F_Calc : LTIME
VAR_INPUT
    tIn : TIME;
END_VAR
VAR
    pDyn : POINTER TO INT;
    itfA : I_Base;
    itfB : I_Dev;
    udiSize : UDINT;
END_VAR
