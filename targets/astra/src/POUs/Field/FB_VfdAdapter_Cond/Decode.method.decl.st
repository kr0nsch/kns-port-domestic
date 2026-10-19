// Разобрать регистры чтения ПЧ (FC3 100, 101) и состояние обмена со слейвом
METHOD Decode
VAR_INPUT
    wStw     : WORD;                // слово состояния (GVL_IO.wP10n_STW)
    uiFact   : UINT;                // фактическая частота, 0,01 Гц (GVL_IO.uiP10n_FACT)
    xSlaveOk : BOOL;                // обмен со слейвом исправен (GVL_IO.xMbOk_RS485_1_Sn)
END_VAR
