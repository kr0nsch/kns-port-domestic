// Шаг 6 цикла: значение для логики xValue и xValid (контракт 12.3, таблица 2.6). Нет корректной Cfg —
// FALSE; OutOfService — удержание; Manual — подмена без задержек; отказ канала — значение отказа xGood
// (тело выставляет его по eFailValue: HoldLast — значение до отказа), xValid = FALSE. Значение подмены
// приходит параметром: метод не читает VAR_IN_OUT (R2)
METHOD PROTECTED SelectValue
VAR_INPUT
    xSubst : BOOL;   // значение подмены stCmd.xSubstValue
END_VAR
