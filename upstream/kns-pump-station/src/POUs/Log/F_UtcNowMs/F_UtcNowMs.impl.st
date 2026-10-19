IF SysTimeRtcHighResGet(pTimestamp := uliNow_ms) = GVL_Const.LOG_RTC_OK
   AND uliNow_ms >= GVL_Const.LOG_UTC_MIN_MS THEN
    F_UtcNowMs := uliNow_ms;
ELSE
    F_UtcNowMs := 0;
END_IF
