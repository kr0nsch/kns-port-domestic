// Напор сети в рабочей точке (бисекция по H); подачи — в arQ. xWithClog = FALSE — как будто
// засоров нет (для тока засорённого насоса). Нет насоса, способного преодолеть статический напор, —
// подачи 0, напор Hgeo − h
METHOD PRIVATE Solve : REAL
VAR_INPUT
    xWithClog : BOOL;       // учитывать засоры
END_VAR
VAR
    rStatic : REAL;         // статический напор Hgeo − h
    rLo     : REAL;         // границы бисекции по напору
    rHi     : REAL;
    rMid    : REAL;
    rTotal  : REAL;         // подача станции при rMid
    uiIter  : UINT;         // шаг бисекции
    uiI     : UINT;         // индекс насоса
END_VAR
