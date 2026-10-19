IF ltReal <= ltBaseReal THEN
    ScaledAt := ltBaseScaled;
    RETURN;
END_IF

ltElapsed := ltReal - ltBaseReal;
IF lrScaleAct <= 1.0 THEN
    // k = 1 (Update не даёт меньше): без перевода в LREAL — точно при любой длительности
    ScaledAt := ltBaseScaled + ltElapsed;
ELSE
    // LREAL точен до 2^53 нс (≈ 104 сут); дальше округление монотонно
    ScaledAt := ltBaseScaled + ULINT_TO_LTIME(LREAL_TO_ULINT(ULINT_TO_LREAL(LTIME_TO_ULINT(ltElapsed)) * lrScaleAct));
END_IF
