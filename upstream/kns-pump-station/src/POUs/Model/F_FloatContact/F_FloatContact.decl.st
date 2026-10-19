// Назначение: НЗ-контакт поплавкового выключателя в модели (TRUE — норма, контакт замкнут).
//             Верхний поплавок срабатывает при уровне ≥ отметки, нижний — при уровне ≤ отметки;
//             инъекция E_SimFloatStuck: StuckNormal — не срабатывает, StuckTripped — сработал
//             (то же — обрыв цепи НЗ-контакта). Неконечный уровень — контакт в норме.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 11.2; docs/03_io_list.md (LS102, LS103)
FUNCTION F_FloatContact : BOOL
VAR_INPUT
    rLevel_m   : REAL;              // истинный уровень
    rMark_m    : REAL;              // отметка поплавка
    xHighFloat : BOOL;              // TRUE — верхний (срабатывает выше отметки), FALSE — нижний
    eStuck     : E_SimFloatStuck;   // инъекция залипания
END_VAR
VAR
    xTripped : BOOL;                // поплавок сработал (контакт разомкнут)
END_VAR
