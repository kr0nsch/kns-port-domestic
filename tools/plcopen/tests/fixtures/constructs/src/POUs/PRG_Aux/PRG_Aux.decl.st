// Назначение: программа с методом; комментарии всех видов
// Автор:      <ИМЯ ФАМИЛИЯ>
// Версия:     0.1.0
// Документ:   docs/plcopen.md
PROGRAM PRG_Aux
VAR
    fbValve : FB_Valve;
    itfPos : I_Positioner;
    itfLock : I_Lockable;
    iCalls : INT;
    wsMsg : WSTRING(32) := "Задвижка <закрыта> & 'ok'";
    sMsg : STRING(32) := 'a$'b"c <&>';
END_VAR
VAR_EXTERNAL
    xDoRun : BOOL;              // выход из GVL_Io (необязательное объявление CODESYS)
END_VAR
