// Время контура для системного времени ltReal: ltBaseScaled + (ltReal − ltBaseReal) · k.
// Разность считается только при ltReal > ltBaseReal (LTIME без знака, L7 контракта библиотеки)
METHOD PRIVATE ScaledAt : LTIME
VAR_INPUT
    ltReal : LTIME;      // системное время
END_VAR
VAR
    ltElapsed : LTIME;   // прошло системного времени с перебазирования
END_VAR
