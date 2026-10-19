// Назначение: индексы слотов тревог запорной арматуры. Нестрогое перечисление: им
//             индексируются массивы.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Valve.md
{attribute 'qualified_only'}
TYPE E_ValveAlarm :
(
    FailToOpen   := 0,   // не открылась за tTravel
    FailToClose  := 1,   // не закрылась за tTravel
    BothLimits   := 2,   // оба концевика
    PositionLost := 3,   // уход с концевика без команды
    TorqueTrip   := 4,   // муфта в ходе
    ExtFault     := 5,   // авария привода
    InterlockAct := 6    // действует блокировка (по умолчанию выключена)
) UINT;
END_TYPE
