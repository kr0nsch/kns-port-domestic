// Структура-наследник базовой
TYPE ST_Derived EXTENDS ST_Base :
STRUCT
    tDelay : TIME := T#5S;
    ltStamp : LTIME;
    pData : POINTER TO INT;
END_STRUCT
END_TYPE
