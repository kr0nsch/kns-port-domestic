// В имитации регистры и признаки обмена GVL_IO пишет модель объекта (PRG_PlantModel)
IF GVL_Sim.xSimulation THEN
    RETURN;
END_IF

// 1. ПЧ Н1…Н3, чтение: слово состояния, фактическая частота, ток, код аварии (те же регистры, что у мастера CODESYS)
GVL_IO.wP101_STW := awP101Rd[GVL_ConstRegul.MB_VFD_RD_STW];
GVL_IO.uiP101_FACT := WORD_TO_UINT(awP101Rd[GVL_ConstRegul.MB_VFD_RD_FACT]);
GVL_IO.uiIT111 := WORD_TO_UINT(awP101Rd[GVL_ConstRegul.MB_VFD_RD_IT]);
GVL_IO.uiP101_FCODE := WORD_TO_UINT(awP101Rd[GVL_ConstRegul.MB_VFD_RD_FCODE]);

GVL_IO.wP102_STW := awP102Rd[GVL_ConstRegul.MB_VFD_RD_STW];
GVL_IO.uiP102_FACT := WORD_TO_UINT(awP102Rd[GVL_ConstRegul.MB_VFD_RD_FACT]);
GVL_IO.uiIT121 := WORD_TO_UINT(awP102Rd[GVL_ConstRegul.MB_VFD_RD_IT]);
GVL_IO.uiP102_FCODE := WORD_TO_UINT(awP102Rd[GVL_ConstRegul.MB_VFD_RD_FCODE]);

GVL_IO.wP103_STW := awP103Rd[GVL_ConstRegul.MB_VFD_RD_STW];
GVL_IO.uiP103_FACT := WORD_TO_UINT(awP103Rd[GVL_ConstRegul.MB_VFD_RD_FACT]);
GVL_IO.uiIT131 := WORD_TO_UINT(awP103Rd[GVL_ConstRegul.MB_VFD_RD_IT]);
GVL_IO.uiP103_FCODE := WORD_TO_UINT(awP103Rd[GVL_ConstRegul.MB_VFD_RD_FCODE]);

// 2. ПЧ Н1…Н3, запись: слово управления и задание частоты. PRG_FieldOut пишет их в конце MainTask, поэтому
//    в канал уходят значения прошлого цикла (20 мс — меньше периода опроса)
awP101Wr[GVL_ConstRegul.MB_VFD_WR_CTW] := GVL_IO.wP101_CTW;
awP101Wr[GVL_ConstRegul.MB_VFD_WR_FREF] := UINT_TO_WORD(GVL_IO.uiP101_FREF);
awP102Wr[GVL_ConstRegul.MB_VFD_WR_CTW] := GVL_IO.wP102_CTW;
awP102Wr[GVL_ConstRegul.MB_VFD_WR_FREF] := UINT_TO_WORD(GVL_IO.uiP102_FREF);
awP103Wr[GVL_ConstRegul.MB_VFD_WR_CTW] := GVL_IO.wP103_CTW;
awP103Wr[GVL_ConstRegul.MB_VFD_WR_FREF] := UINT_TO_WORD(GVL_IO.uiP103_FREF);

// 3. TT403: REAL из двух регистров, старшее слово первым (HL). Неконечное значение (NaN, ±Inf)
//    PL.FB_AnalogInput считает недостоверным (ClassifySignal)
uTT403.dwValue := SHL(WORD_TO_DWORD(awTT403Rd[GVL_ConstRegul.MB_REAL_HI]), GVL_ConstRegul.MB_WORD_BITS)
                  OR WORD_TO_DWORD(awTT403Rd[GVL_ConstRegul.MB_REAL_LO]);
GVL_IO.rTT403 := uTT403.rValue;

// 4. Признаки обмена — по статусу каналов чтения (запись идёт тем же слейвам по той же линии)
GVL_IO.xMbOk_RS485_1_S1 := F_MbStatusOk_Regul(iStatus := TO_INT(eP101Status));
GVL_IO.xMbOk_RS485_1_S2 := F_MbStatusOk_Regul(iStatus := TO_INT(eP102Status));
GVL_IO.xMbOk_RS485_1_S3 := F_MbStatusOk_Regul(iStatus := TO_INT(eP103Status));
GVL_IO.xMbOk_RS485_2_S10 := F_MbStatusOk_Regul(iStatus := TO_INT(eTT403Status));
