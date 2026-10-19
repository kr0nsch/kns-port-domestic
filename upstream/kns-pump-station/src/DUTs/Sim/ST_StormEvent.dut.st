// Назначение: ливень генератора модели: начало в сутках, длительность, пик притока
//             (форма — трапеция: рост 15 %, полка 50 %, спад 35 % длительности).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 3.3, 11.2
{attribute 'qualified_only'}
TYPE ST_StormEvent :
STRUCT
    rStart_h  : REAL;               // начало, ч от полуночи суток
    tDuration : TIME;
    rPeak_m3h : REAL;
END_STRUCT
END_TYPE
