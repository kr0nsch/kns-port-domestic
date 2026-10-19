// Команды двигателя от HMI (DUT в папке проекта)
TYPE ST_MotorCmd :
STRUCT
    xStart : BOOL;
    xStop : BOOL;
    eMode : E_Mode := E_Mode.OutOfService;
END_STRUCT
END_TYPE
