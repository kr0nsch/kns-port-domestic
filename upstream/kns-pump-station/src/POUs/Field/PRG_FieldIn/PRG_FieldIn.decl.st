// Назначение: полевой слой, вход (MainTask, первым): часы контура GVL_Time.fbClockMain (ускорение — только
//             в имитации) и время процесса GVL_Time.lrMainNow_s; в первом цикле — действующий признак имитации
//             GVL_Sim.xSimulation (запрос и разрешение сборки SIM_ALLOWED), признак действительных входов
//             GVL_Sim.xIoReady (в имитации — после первого цикла модели); адаптеры ПЧ Н1…Н3 разбирают
//             регистры чтения в переменные GVL_IO, которые читает PRG_Devices (xP10n_CommOk, VfdReady, VfdRun,
//             VfdFault, rP10n_SpeedAct_pct).
// Автор:      kr0nsch
// Версия:     0.2.0
// Документ:   docs/DESIGN.md, раздел 8.1
PROGRAM PRG_FieldIn
VAR
    fbVfdP101 : FB_VfdAdapter_Cond; // адаптер ПЧ насоса Н1 (слейв 1 RS485-1); Encode — в PRG_FieldOut
    fbVfdP102 : FB_VfdAdapter_Cond; // Н2 (слейв 2)
    fbVfdP103 : FB_VfdAdapter_Cond; // Н3 (слейв 3)
    xInitDone : BOOL;               // первый цикл выполнен
END_VAR
