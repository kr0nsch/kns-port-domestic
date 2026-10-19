// Состояние двигателя для HMI (DUT во вложенной папке Motor/Status)
TYPE ST_MotorSts :
STRUCT
    xRun : BOOL;
    uiStarts : UINT;
    eMode : E_Mode := E_Mode.OutOfService;
END_STRUCT
END_TYPE
