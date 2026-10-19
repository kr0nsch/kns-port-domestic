// Назначение: все сигналы модели для входов GVL_IO: входы модулей AI/DI, регистры чтения ПЧ и
//             TT403, состояние обмена со слейвами Modbus. Поля называются так же, как переменные
//             GVL_IO (вывод iolistgen по docs/03_io_list.csv): PRG_PlantModel копирует поле в
//             одноимённую переменную. Модель пишет только входы GVL_IO (ARCHITECTURE, раздел 4).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 3.3, 11.1; docs/03_io_list.md
{attribute 'qualified_only'}
TYPE ST_PlantIo :
STRUCT
    // --- входы AI, мА ---
    rLT101_mA : REAL;               // A1.1 уровень, 0…5 м
    rPT201_mA : REAL;               // A1.2 давление в коллекторе, 0…10 бар
    rFT202_mA : REAL;               // A1.3 расход, 0…500 м³/ч
    rAT401_mA : REAL;               // A1.4 H2S, 0…40 мг/м³
    rAT402_mA : REAL;               // A1.5 CH4, 0…100 % НКПР
    // --- входы DI шкафа и павильона ---
    xLS102 : BOOL;                  // поплавок «аварийно высокий», НЗ: TRUE — норма
    xLS103 : BOOL;                  // поплавок «сухой ход», НЗ: TRUE — норма
    xLS203 : BOOL;                  // затопление камеры задвижек
    xES301 : BOOL;                  // напряжение на вводе в норме
    xYS302 : BOOL;                  // ИБП: работа от батарей
    xYS303 : BOOL;                  // ИБП: неисправность
    xZS404 : BOOL;                  // дверь павильона открыта
    xYS405 : BOOL;                  // пожар
    xHS501 : BOOL;                  // кнопка «Сброс аварий»
    xHS502 : BOOL;                  // кнопка «Отключить звук»
    xV1_RFB : BOOL;                 // В1: блок-контакт пускателя
    xV1_FLT : BOOL;                 // В1: автомат защиты двигателя
    // --- входы DI насосов ---
    xP101_RFB : BOOL;               // Н1: реле ПЧ «Работа»
    xP101_FLT : BOOL;               // Н1: реле ПЧ «Авария»
    xHS114 : BOOL;                  // Н1: «Местное»
    xTS112 : BOOL;                  // Н1: термовыключатели, НЗ: TRUE — норма
    xMS113 : BOOL;                  // Н1: протечка в камеру статора
    xP102_RFB : BOOL;
    xP102_FLT : BOOL;
    xHS124 : BOOL;
    xTS122 : BOOL;
    xMS123 : BOOL;
    xP103_RFB : BOOL;
    xP103_FLT : BOOL;
    xHS134 : BOOL;
    xTS132 : BOOL;
    xMS133 : BOOL;
    // --- регистры чтения ПЧ (RS485-1, FC3 100…103) ---
    wP101_STW : WORD;               // слово состояния
    uiP101_FACT : UINT;             // фактическая частота, 0,01 Гц
    uiIT111 : UINT;                 // ток двигателя, 0,1 А
    uiP101_FCODE : UINT;            // код последней аварии
    wP102_STW : WORD;
    uiP102_FACT : UINT;
    uiIT121 : UINT;
    uiP102_FCODE : UINT;
    wP103_STW : WORD;
    uiP103_FACT : UINT;
    uiIT131 : UINT;
    uiP103_FCODE : UINT;
    // --- RS485-2: температура павильона ---
    rTT403 : REAL;                  // °C
    // --- состояние обмена со слейвами ---
    xMbOk_RS485_1_S1 : BOOL;
    xMbOk_RS485_1_S2 : BOOL;
    xMbOk_RS485_1_S3 : BOOL;
    xMbOk_RS485_2_S10 : BOOL;
END_STRUCT
END_TYPE
