IF uliUtc_ms = 0 THEN
    F_UtcToIso := '';
    RETURN;
END_IF
udiSec := ULINT_TO_UDINT(uliUtc_ms / MS_PER_S);
udiSecOfDay := udiSec MOD S_PER_DAY;
// дата: дни от 1970 → год, месяц, день (все величины неотрицательные)
udiZ := udiSec / S_PER_DAY + EPOCH_SHIFT;
udiEra := udiZ / DAYS_PER_ERA;
udiDoe := udiZ - udiEra * DAYS_PER_ERA;
udiYoe := (udiDoe - udiDoe / DAYS_4Y + udiDoe / DAYS_100Y - udiDoe / DAYS_400Y_M1) / DAYS_PER_YEAR;
udiDoy := udiDoe - (DAYS_PER_YEAR * udiYoe + udiYoe / YEARS_4 - udiYoe / YEARS_100);
udiMp := (MONTHS_5 * udiDoy + 2) / DAYS_5M;
udiDay := udiDoy - (DAYS_5M * udiMp + 2) / MONTHS_5 + 1;
IF udiMp < JAN_FROM_MAR THEN
    udiMonth := udiMp + MAR_SHIFT;
ELSE
    udiMonth := udiMp - MAR_BACK;
END_IF
udiYear := udiYoe + udiEra * YEARS_PER_ERA;
IF udiMonth <= FEB THEN
    udiYear := udiYear + 1;
END_IF
sDate := CONCAT(CONCAT(F_ZeroPad(udiValue := udiYear, uiDigits := DIGITS_YEAR), '-'),
                CONCAT(CONCAT(F_ZeroPad(udiValue := udiMonth, uiDigits := 2), '-'),
                       F_ZeroPad(udiValue := udiDay, uiDigits := 2)));
sTime := CONCAT(CONCAT(F_ZeroPad(udiValue := udiSecOfDay / S_PER_HOUR, uiDigits := 2), ':'),
                CONCAT(CONCAT(F_ZeroPad(udiValue := udiSecOfDay MOD S_PER_HOUR / S_PER_MIN, uiDigits := 2), ':'),
                       F_ZeroPad(udiValue := udiSecOfDay MOD S_PER_MIN, uiDigits := 2)));
sMs := F_ZeroPad(udiValue := ULINT_TO_UDINT(uliUtc_ms MOD MS_PER_S), uiDigits := DIGITS_MS);
F_UtcToIso := CONCAT(CONCAT(sDate, 'T'), CONCAT(CONCAT(sTime, '.'), CONCAT(sMs, 'Z')));
