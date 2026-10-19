dwState := F_Xorshift32(dwState := dwState);
Draw := UDINT_TO_LREAL(DWORD_TO_UDINT(dwState AND GVL_Const.SIM_U24_MASK)) / REAL_TO_LREAL(GVL_Const.SIM_U24_SCALE);
