// Назначение: абстрактная база с источником времени (SUPER^ и LTIME() в комментарии не считаются)
{attribute 'call_after_init'}
FUNCTION_BLOCK ABSTRACT FB_Base IMPLEMENTS I_Dev
VAR_IN_OUT CONSTANT
    stCfg : ST_Base;
END_VAR
VAR
    ltLast : LTIME;
    itfNext : I_Base;
    refValue : REFERENCE TO DINT;
    pValue : POINTER TO DINT;
    sNote : STRING := 'SUPER^ и __NEW в строке тоже не считаются';
END_VAR
VAR_STAT
    diCount : DINT;
END_VAR
