F_Calc := TIME_TO_LTIME(tIn) + LT#1S + LTIME#2MS;
pDyn := __NEW(INT);
__DELETE(pDyn);
IF __QUERYINTERFACE(itfA, itfB) THEN
    udiSize := SIZEOF(tIn);
END_IF
{IF defined(DEBUG)}
udiSize := 0;
{END_IF}
