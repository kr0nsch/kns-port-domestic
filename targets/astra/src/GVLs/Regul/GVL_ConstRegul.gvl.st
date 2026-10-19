// Назначение: константы сборки для ПЛК REGUL: раскладка массивов каналов драйвера Modbus Serial Master
//             и таблица статусов канала для адаптера PRG_ModbusMap_Regul. Константы приложения — в
//             GVL_Const; здесь только то, чего нет у флагмана в CODESYS.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   targets/astra/README.md; docs/differences.md, раздел 7
// PORT: [comm] новый объект: константы адаптера Modbus RTU на REGUL [F57, F58]
{attribute 'qualified_only'}
VAR_GLOBAL CONSTANT
    // Канал чтения ПЧ: FC3, 4x 100…103 — как у флагмана (docs/modbus_master_map.csv), 4 регистра
    MB_VFD_RD_STW : INT := 0;       // слово состояния
    MB_VFD_RD_FACT : INT := 1;      // фактическая частота, 0,01 Гц
    MB_VFD_RD_IT : INT := 2;        // ток двигателя, 0,1 А
    MB_VFD_RD_FCODE : INT := 3;     // код последней аварии
    MB_VFD_RD_LAST : INT := 3;      // последний индекс массива канала чтения
    // Канал записи ПЧ: FC16, 4x 0…1, 2 регистра. Тип канала — Timer (запись с периодом, как цикличный
    // канал мастера CODESYS): сторожевому таймеру связи ПЧ нужны регулярные запросы
    MB_VFD_WR_CTW : INT := 0;       // слово управления
    MB_VFD_WR_FREF : INT := 1;      // задание частоты, 0,01 Гц
    MB_VFD_WR_LAST : INT := 1;      // последний индекс массива канала записи
    // TT403: FC4, 3x 0…1, REAL, старшее слово первым (HL)
    MB_REAL_HI : INT := 0;
    MB_REAL_LO : INT := 1;
    MB_REAL_LAST : INT := 1;
    MB_WORD_BITS : UINT := 16;      // сдвиг старшего слова
    // Статус канала — перечисление ChannelStatus со значениями 0…6 [F58]. Какое значение означает «обмен
    // исправен», в документации не описано: до проверки ни одно значение не считается исправным, и адаптер
    // показывает потерю связи — безопасная сторона (насосы управляются проводами, станция — по ступеням)
    MB_STATUS_MAX : INT := 6;
    // PORT: [comm] проверить в Astra.IDE — значения ChannelStatus «обмен исправен» (E2)
    MB_STATUS_OK : ARRAY[0..GVL_ConstRegul.MB_STATUS_MAX] OF BOOL := [FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE];
END_VAR
