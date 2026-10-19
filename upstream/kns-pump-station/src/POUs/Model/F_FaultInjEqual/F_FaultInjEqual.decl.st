// Назначение: сравнение двух наборов инъекций ST_FaultInjection поле за полем (структуры в CODESYS
//             оператором «=» не сравниваются; поля REAL — по битам, чтобы NaN был равен NaN).
//             FB_PlantModel по нему считает изменения инъекций
//             (stSimSts.udiFaultSeq → событие журнала 101021). Новое поле ST_FaultInjection добавляется
//             и сюда — тест FaultSeqCountsChanges меняет каждое поле.
// Автор:      kr0nsch
// Версия:     0.1.1
// Документ:   docs/DESIGN.md, разделы 3.3, 11.1
FUNCTION F_FaultInjEqual : BOOL
VAR_IN_OUT CONSTANT
    stA : ST_FaultInjection;
    stB : ST_FaultInjection;
END_VAR
VAR
    uiI : UINT;             // индекс насоса или датчика
    uBitsA : PL.U_RealBits; // поле REAL набора A как биты (сравнение NaN)
    uBitsB : PL.U_RealBits;
END_VAR
