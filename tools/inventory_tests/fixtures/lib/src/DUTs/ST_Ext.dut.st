// Наследник структуры: 64-битные и широкие строки, поддиапазон
TYPE ST_Ext EXTENDS ST_Base :
STRUCT
    lwMask : LWORD;
    wsText : WSTRING(40);
    iPct : INT(0..100);
END_STRUCT
END_TYPE
