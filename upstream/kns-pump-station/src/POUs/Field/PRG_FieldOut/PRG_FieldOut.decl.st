// Назначение: полевой слой, выход (MainTask, последним): адаптеры ПЧ Н1…Н3 (экземпляры PRG_FieldIn)
//             собирают слово управления и задание частоты из выходов PL.FB_MotorVfd в регистры записи
//             GVL_IO.wP10n_CTW, GVL_IO.uiP10n_FREF (FC16 0, 1).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 8.3
PROGRAM PRG_FieldOut
