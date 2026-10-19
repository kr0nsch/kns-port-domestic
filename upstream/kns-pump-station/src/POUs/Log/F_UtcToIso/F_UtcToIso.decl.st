// Назначение: метка UTC журнала (мс от 1970) → строка ISO 8601 «2026-10-16T07:41:05.120Z» для CSV; 0 — пустая
//             строка (часы были недоступны). Дата — целочисленный алгоритм civil_from_days (H. Hinnant,
//             «chrono-Compatible Low-Level Date Algorithms»), без зависимости от формата DT_TO_STRING;
//             годы 1970…2105 (секунды от 1970 — UDINT).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 9.2
FUNCTION F_UtcToIso : STRING(GVL_Const.LOG_ISO_LEN)
VAR_INPUT
    uliUtc_ms : ULINT;              // мс от 1970-01-01T00:00:00Z; 0 — нет метки
END_VAR
VAR
    udiSec      : UDINT;            // секунды от 1970
    udiSecOfDay : UDINT;            // секунды от начала суток
    udiZ        : UDINT;            // дни от 0000-03-01
    udiEra      : UDINT;            // 400-летний цикл
    udiDoe      : UDINT;            // день цикла, 0…146096
    udiYoe      : UDINT;            // год цикла, 0…399
    udiDoy      : UDINT;            // день года от 1 марта, 0…365
    udiMp       : UDINT;            // месяц от марта, 0…11
    udiYear     : UDINT;
    udiMonth    : UDINT;
    udiDay      : UDINT;
    sDate       : STRING(GVL_Const.LOG_ISO_LEN);   // ГГГГ-ММ-ДД
    sTime       : STRING(GVL_Const.LOG_ISO_LEN);   // чч:мм:сс
    sMs         : STRING(GVL_Const.LOG_ISO_LEN);   // ммм
END_VAR
VAR CONSTANT
    MS_PER_S      : ULINT := 1000;
    S_PER_DAY     : UDINT := 86400;
    S_PER_HOUR    : UDINT := 3600;
    S_PER_MIN     : UDINT := 60;
    EPOCH_SHIFT   : UDINT := 719468;  // дней от 0000-03-01 до 1970-01-01
    DAYS_PER_ERA  : UDINT := 146097;  // дней в 400 годах
    DAYS_4Y       : UDINT := 1460;    // дней в 4 годах без високосного дня
    DAYS_100Y     : UDINT := 36524;
    DAYS_400Y_M1  : UDINT := 146096;
    DAYS_PER_YEAR : UDINT := 365;
    YEARS_4       : UDINT := 4;
    YEARS_100     : UDINT := 100;
    YEARS_PER_ERA : UDINT := 400;
    DAYS_5M       : UDINT := 153;     // дней в пяти месяцах с марта
    MONTHS_5      : UDINT := 5;
    JAN_FROM_MAR  : UDINT := 10;      // январь в счёте месяцев от марта
    MAR_SHIFT     : UDINT := 3;       // месяц от марта → календарный (март = 3)
    MAR_BACK      : UDINT := 9;       // январь, февраль: месяц от марта − 9
    FEB           : UDINT := 2;
    DIGITS_YEAR   : UINT := 4;
    DIGITS_MS     : UINT := 3;
END_VAR
