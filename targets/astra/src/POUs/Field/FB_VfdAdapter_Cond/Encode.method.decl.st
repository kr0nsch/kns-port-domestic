// Собрать регистры записи ПЧ (FC16 0, 1): бит сброса аварии, пока xQReset (импульс библиотеки 1 с длиннее
// цикла записи Modbus), задание частоты — LIMIT(0, rSpeedRef_pct, 100) · VFD_COUNTS_PER_PCT с округлением;
// неконечное задание — 0
METHOD Encode
VAR_INPUT
    xQReset       : BOOL;           // импульс сброса аварии ПЧ (GVL_IO.xP10n_VfdQReset ← fbP10n.xQReset)
    rSpeedRef_pct : REAL;           // задание на ПЧ, % (GVL_IO.rP10n_SpeedRef_pct ← fbP10n.rSpeedRef_pct)
END_VAR
