// Объединение: одно слово как целое и как биты
TYPE U_Raw :
UNION
    wWord : WORD;
    aBytes : ARRAY[0..1] OF BYTE;
END_UNION
END_TYPE
