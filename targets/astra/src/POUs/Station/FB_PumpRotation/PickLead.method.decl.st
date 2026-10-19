// Ведущий среди запрошенных насосов; xPreferComm (ПИД) — сначала насосы со связью с ПЧ, если
// таких нет — любой запрошенный. 0 — нет запрошенных
METHOD PRIVATE PickLead : UINT
VAR_INPUT
    xPreferComm : BOOL;                 // предпочесть насосы со связью
END_VAR
