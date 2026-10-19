// Назначение: модель объекта в задаче PlantModelTask (только сборка имитации). В реальном режиме
//             (GVL_Sim.xSimulation = FALSE) сразу выходит и входы GVL_IO не трогает. В имитации:
//             часы модели (ускорение GVL_Sim.stSimCfg.rTimeScale, перебазирование в начале цикла),
//             чтение выходов ПЛК из GVL_IO, вызов FB_PlantModel, копирование ST_PlantIo во входы GVL_IO
//             и состояния в GVL_Sim.stSimSts. Модель пишет только входы GVL_IO (ARCHITECTURE, раздел 4);
//             журнал не вызывает: событие изменения инъекций (101021) пишет PRG_Station по udiFaultSeq.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, разделы 11.1, 12; docs/ARCHITECTURE.md, разделы 4, 9, 11
PROGRAM PRG_PlantModel
VAR
    fbPlant : FB_PlantModel;                                    // модель объекта
    axRun   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF BOOL;       // выходы ПЛК для модели
    awCtw   : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF WORD;
    auiFref : ARRAY[1..GVL_Const.STN_PUMP_COUNT] OF UINT;
END_VAR
