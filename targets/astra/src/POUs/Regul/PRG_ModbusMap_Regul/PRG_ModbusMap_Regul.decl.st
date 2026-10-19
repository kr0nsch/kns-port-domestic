// Назначение: слой Modbus RTU сборки для ПЛК REGUL: массивы WORD каналов устройств Modbus Serial Outer
//             Slave ↔ регистры GVL_IO (ПЧ Н1…Н3 на RS485-1, TT403 на RS485-2) и признаки обмена
//             GVL_IO.xMbOk_* по статусу каналов чтения. Заменяет мастер Modbus CODESYS с диагностикой слейвов
//             (у флагмана — слой Modbus сборки ПЛК210). Вызывается первой в MainTask только в сборке для ПЛК
//             (GVL_Const.SIM_ALLOWED = FALSE) и на стенде с Modbus TCP вместо RTU; в имитации регистры GVL_IO
//             пишет модель объекта, программа сразу выходит.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   targets/astra/README.md; docs/migration_checklist.md, раздел 4
// PORT: [comm] новый объект: Modbus RTU на REGUL — каналы Modbus Serial Outer Slave [F57, F58]
PROGRAM PRG_ModbusMap_Regul
VAR
    // Data каналов — привязать в «Соотнесении входов/выходов» каналов слейвов (E1, E2)
    awP101Rd : ARRAY[0..GVL_ConstRegul.MB_VFD_RD_LAST] OF WORD;  // слейв 1: канал FC3 4x 100, 4 регистра, Timer
    awP102Rd : ARRAY[0..GVL_ConstRegul.MB_VFD_RD_LAST] OF WORD;  // слейв 2: то же
    awP103Rd : ARRAY[0..GVL_ConstRegul.MB_VFD_RD_LAST] OF WORD;  // слейв 3: то же
    awP101Wr : ARRAY[0..GVL_ConstRegul.MB_VFD_WR_LAST] OF WORD;  // слейв 1: канал FC16 4x 0, 2 регистра, Timer
    awP102Wr : ARRAY[0..GVL_ConstRegul.MB_VFD_WR_LAST] OF WORD;  // слейв 2: то же
    awP103Wr : ARRAY[0..GVL_ConstRegul.MB_VFD_WR_LAST] OF WORD;  // слейв 3: то же
    awTT403Rd : ARRAY[0..GVL_ConstRegul.MB_REAL_LAST] OF WORD;   // RS485-2, слейв 10: канал FC4 3x 0, 2 регистра
    // Status каналов чтения — привязать к Status тех же каналов
    // PORT: [comm] проверить в Astra.IDE — тип PsModbusSerialMaster.ChannelStatus, привязка Status [F58] (E2)
    eP101Status : PsModbusSerialMaster.ChannelStatus;
    eP102Status : PsModbusSerialMaster.ChannelStatus;
    eP103Status : PsModbusSerialMaster.ChannelStatus;
    eTT403Status : PsModbusSerialMaster.ChannelStatus;
    uTT403 : PL.U_RealBits;     // REAL из двух регистров
END_VAR
