// Базовая структура: начальные значения, массив, строка, комментарии
TYPE ST_Base :
STRUCT
    xEnable : BOOL := TRUE;               // разрешение
    iCount : INT;                         (* счётчик *)
    rValue_bar : REAL := 1.5;
    sName : STRING(32) := 'base';
    wsLabel : WSTRING(16) := "Насос";
    aiData : ARRAY[0..3] OF INT := [1, 2, 3, 4];
    eMode : E_Mode := E_Mode.Auto;
END_STRUCT
END_TYPE
