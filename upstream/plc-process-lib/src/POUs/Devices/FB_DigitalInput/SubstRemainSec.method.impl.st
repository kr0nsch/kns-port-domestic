IF eMode = E_DeviceMode.Manual AND stCfgLkg.tSubstMax > T#0S THEN
    lrRemain_s := F_TimeToSec(tIn := fbSubst.tRemaining);
    udiRemain_s := LREAL_TO_UDINT(lrRemain_s);
    IF UDINT_TO_LREAL(udiRemain_s) < lrRemain_s THEN
        udiRemain_s := udiRemain_s + 1;
    END_IF
    SubstRemainSec := UDINT_TO_UINT(MIN(udiRemain_s, UINT_TO_UDINT(GVL_Const.UINT_MAX)));
ELSE
    SubstRemainSec := 0;
END_IF
