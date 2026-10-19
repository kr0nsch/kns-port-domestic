// Насос uiA предпочтительнее uiB по режиму чередования (04 §8.1); uiB = 0 — любой лучше.
// RunHours: меньше RunSeconds, затем меньше Starts, затем меньший номер; Cyclic: ближе по кругу
// к uiNext; Fixed и значение вне перечисления: меньший номер
METHOD PRIVATE Better : BOOL
VAR_INPUT
    uiA    : UINT;                  // кандидат
    uiB    : UINT;                  // лучший до него; 0 — нет
    eRot   : E_RotationMode;        // режим чередования
    uiNext : UINT;                  // Cyclic: следующий ведущий 1…STN_PUMP_COUNT
END_VAR
VAR
    uiDistA : UINT;                 // Cyclic: шагов по кругу от uiNext до uiA
    uiDistB : UINT;                 // то же до uiB
END_VAR
