// Назначение: ограничение значения диапазоном [rMin, rMax]; при rMin > rMax границы меняются местами
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
FUNCTION F_Clamp : REAL
VAR_INPUT
    rValue : REAL;      // значение
    rMin : REAL;        // нижняя граница
    rMax : REAL;        // верхняя граница
END_VAR
VAR
    rLow : REAL;
    rHigh : REAL;
END_VAR
