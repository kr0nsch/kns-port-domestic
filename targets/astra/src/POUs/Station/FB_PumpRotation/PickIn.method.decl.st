// Лучший незапрошенный доступный насос группы по режиму чередования; 0 — нет такого.
// xRequireReady — только ReadyToStart, xRequireCommOk — только со связью с ПЧ
METHOD PRIVATE PickIn : UINT
VAR_INPUT
    eRot           : E_RotationMode;    // режим чередования
    uiNext         : UINT;              // Cyclic: следующий ведущий
    xRequireCommOk : BOOL;              // только насосы со связью
    xRequireReady  : BOOL;              // только готовые к пуску
END_VAR
VAR
    uiIdx : UINT;                       // номер насоса
END_VAR
