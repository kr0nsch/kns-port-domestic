SUPER^();
IF NOT xLocked THEN
    rPos_pct := F_Clamp(rValue := rSetpoint_pct, rMin := 0.0, rMax := POS_MAX);
END_IF
