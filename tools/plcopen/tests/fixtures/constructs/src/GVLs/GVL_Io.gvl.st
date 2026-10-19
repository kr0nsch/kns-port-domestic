// Входы-выходы и сохраняемые значения
VAR_GLOBAL
    xDiStart AT %IX0.0 : BOOL;      // кнопка «Пуск»
    xDoRun AT %QX0.0 : BOOL;
    iAiLevel AT %IW2 : INT;
    astCmd : ARRAY[1..GVL_Const.MAX_ITEMS] OF ST_MotorCmd;
END_VAR
VAR_GLOBAL RETAIN
    udiRunHours : UDINT;
END_VAR
VAR_GLOBAL CONSTANT
    IO_CHANNELS : INT := 2;         // число каналов (константа в одном списке с переменными)
END_VAR
