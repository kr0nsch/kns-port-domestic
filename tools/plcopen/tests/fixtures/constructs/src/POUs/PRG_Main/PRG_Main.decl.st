// Назначение: точка входа — вызывает все объекты примера
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
PROGRAM PRG_Main
VAR
    fbMotor : FB_Motor;
    itfDevice : I_Device;
    itfReset : I_Resettable;
    fbCounter : FB_Counter;
    stCmd : ST_MotorCmd;
    stSts : ST_MotorSts;
    stDerived : ST_Derived;
    uRaw : U_Raw;
    ePercent : T_Percent := 50;
    sName : T_Name := 'pump';
    eColor : E_Color := E_Color.Green;
    arBuf : ARRAY[0..2] OF REAL := [3(1.0)];
    rOut : REAL;
    lrSum : LREAL;
    pValue : POINTER TO REAL;
    refValue : REFERENCE TO REAL;
    iStep : INT;
    xOk : BOOL;
END_VAR
