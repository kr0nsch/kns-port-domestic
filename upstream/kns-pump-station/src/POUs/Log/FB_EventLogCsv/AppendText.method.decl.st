// Дописать строку в буфер порции (ASCII-байты без завершающего нуля); не помещается — обрезается по буферу
METHOD PRIVATE AppendText
VAR_INPUT
    sText : STRING(GVL_Const.LOG_CSV_LINE_LEN);
END_VAR
VAR
    pChar : POINTER TO BYTE;       // очередной символ строки
    iI     : INT;                   // номер символа
END_VAR
