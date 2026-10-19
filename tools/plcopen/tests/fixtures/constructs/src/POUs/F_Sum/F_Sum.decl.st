// Назначение: сумма элементов массива любой длины (VAR_IN_OUT CONSTANT, ARRAY[*])
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
FUNCTION F_Sum : LREAL
VAR_IN_OUT CONSTANT
    arValues : ARRAY[*] OF REAL;
END_VAR
VAR
    diIdx : DINT;
END_VAR
