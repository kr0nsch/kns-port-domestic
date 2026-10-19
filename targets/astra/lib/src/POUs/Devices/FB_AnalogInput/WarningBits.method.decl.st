// Слово wWarning: пока выход за диапазон подтверждён (xOor) — бит по текущей классификации;
// AI_WRN_CLAMPED — значение этого вызова ограничено шкалой (контракт 11.5)
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED WarningBits : WORD
VAR
    wBits : WORD;   // собранные биты
END_VAR
