// сдвиги DWORD отбрасывают старшие биты — арифметика по модулю 2^32, как в эталоне
dwX := dwState;
dwX := dwX XOR SHL(dwX, GVL_Const.SIM_XS_SHIFT_A);
dwX := dwX XOR SHR(dwX, GVL_Const.SIM_XS_SHIFT_B);
dwX := dwX XOR SHL(dwX, GVL_Const.SIM_XS_SHIFT_C);
F_Xorshift32 := dwX;
