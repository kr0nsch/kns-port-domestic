// Ведущий среди запрошенных насосов; xPreferComm (ПИД) — сначала насосы со связью с ПЧ, если
// таких нет — любой запрошенный. 0 — нет запрошенных
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PRIVATE (C3)
METHOD PRIVATE PickLead : UINT
VAR_INPUT
    xPreferComm : BOOL;                 // предпочесть насосы со связью
END_VAR
