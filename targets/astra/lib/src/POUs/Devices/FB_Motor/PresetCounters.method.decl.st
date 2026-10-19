// Запрос записать полные счётчики (замена ПЛК, двигатель после ремонта): наработку и число пусков.
// Применяет ближайший вызов тела (stRetain.udiOpTime_s, udiOpCount; результат Accepted); счётчики
// «с последнего ТО» не меняются. TRUE — запрос принят
METHOD PUBLIC PresetCounters : BOOL
VAR_INPUT
    udiRunTime_s : UDINT;   // наработка всего, с
    udiStarts    : UDINT;   // пусков всего
END_VAR
