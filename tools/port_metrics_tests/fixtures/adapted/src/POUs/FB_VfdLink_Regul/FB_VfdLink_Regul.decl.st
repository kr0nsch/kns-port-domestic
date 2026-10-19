// PORT: адаптер связи с ПЧ через Modbus Serial Master вместо устройства CODESYS
FUNCTION_BLOCK FB_VfdLink_Regul
VAR_INPUT
    awData : ARRAY[0..3] OF WORD;
END_VAR
VAR_OUTPUT
    rSpeed_Hz : REAL;
END_VAR
