// Назначение: программа станции
PROGRAM PRG_Main
VAR
    fbMotor : PL.FB_Motor;
    itfMotor : PL.I_Motor;
    fbTon : TON;
    fbBlink : Util.BLINK;
    hFile : FILE.CAA.HANDLE;
    Mem : PL.ST_Mem;
    iLen : INT;
    dwRaw : DWORD;
    ulTime : ULINT;
END_VAR
