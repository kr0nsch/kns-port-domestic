// Назначение: слоты тревог станции KNS1.* (04 §15, 05_alarm_list.csv): индекс массивов
//             FB_StationAlarms и ST_StationCfg.astAlarm; номер тревоги = STN_ALARM_ID_BASE + slot,
//             бит слов wAlm* — slot - 1. Без strict: перечислением индексируются массивы.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
TYPE E_StationAlarm :
(
    EHL    := 1,    // аварийно высокий уровень (Critical)
    DRY    := 2,    // сухой ход станции (High)
    LACK   := 3,    // недостаточно насосов (High)
    NORES  := 4,    // нет резерва (High)
    ATS    := 5,    // АВР выполнен (Medium)
    FLOAT  := 6,    // управление по поплавкам (Medium)
    LDEV   := 7,    // противоречие поплавка и уровнемера (Medium)
    STEP   := 8,    // ступенчатое вместо ПИД (Low)
    NOAUTO := 9,    // станция в «Ручном» дольше 600 с (Low)
    UL1    := 10,   // недогрузка (сухой ход) Н1 (Medium)
    UL2    := 11,   // недогрузка Н2
    UL3    := 12,   // недогрузка Н3
    SIM    := 13    // режим имитации (Low)
) UINT;
END_TYPE
