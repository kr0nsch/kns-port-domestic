// Назначение: индексы слотов тревог двигателя; слоты 6–7 — только у FB_MotorVfd.
//             Нестрогое перечисление: им индексируются массивы.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Motor.md
{attribute 'qualified_only'}
TYPE E_MotorAlarm :
(
    FailToStart    := 0,   // нет ОС за tFbStart
    FeedbackLost   := 1,   // ОС пропала в работе
    FailToStop     := 2,   // ОС не пропала за tFbStop
    UncommandedRun := 3,   // ОС без команды
    ExtFault       := 4,   // внешняя авария
    InterlockTrip  := 5,   // останов блокировкой в работе
    CommLoss       := 6,   // потеря связи с ПЧ
    SpeedDeviation := 7    // рассогласование задания и фактической скорости ПЧ
) UINT;
END_TYPE
