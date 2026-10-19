// Остаток подмены для stSts.uiSubstRemain_s: целые секунды с округлением вверх (пока подмена идёт,
// остаток не 0), не больше UINT_MAX. 0 — подмены нет или её срок не ограничен (tSubstMax = T#0S)
METHOD PROTECTED SubstRemainSec : UINT
VAR
    lrRemain_s  : LREAL;   // до снятия подмены, с
    udiRemain_s : UDINT;   // то же, целых секунд
END_VAR
