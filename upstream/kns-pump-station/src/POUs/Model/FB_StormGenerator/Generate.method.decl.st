// Ливни суток udiForDay в astWork; результат — их число. Порядок выборок: число ливней, затем для
// каждого — начало, длительность, пик (так же в эталоне tools_project/plant_reference.py)
METHOD PRIVATE Generate : UINT
VAR_INPUT
    udiForDay : UDINT;      // номер суток
END_VAR
VAR
    uiMax    : UINT;        // предел числа ливней
    uiN      : UINT;        // число ливней
    uiK      : UINT;        // индекс ливня
    lrMin_ms : LREAL;       // границы длительности, мс
    lrMax_ms : LREAL;
    rLoPeak  : REAL;        // границы пика (упорядоченные)
    rHiPeak  : REAL;
END_VAR
