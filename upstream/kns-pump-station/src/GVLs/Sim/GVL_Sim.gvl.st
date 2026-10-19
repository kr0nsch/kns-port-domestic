// Назначение: имитация: запрос и действующий признак, параметры модели, команды, инъекции
//             отказов, состояние модели. Модель (PRG_PlantModel, PlantModelTask) пишет stSimSts
//             и входы GVL_IO; признак xSimulation фиксирует PRG_FieldIn в первом цикле, он же
//             выставляет xIoReady, когда входы GVL_IO действительны.
// Автор:      kr0nsch
// Версия:     0.2.0
// Документ:   docs/DESIGN.md, раздел 4.4; docs/ARCHITECTURE.md, раздел 4
{attribute 'qualified_only'}
VAR_GLOBAL
    xSimulationReq  : BOOL := TRUE;      // запрос имитации (меняется только из IDE; в символах — Read)
    xSimulation     : BOOL;              // действующий признак (PRG_FieldIn, первый цикл; Read)
    stSimCfg        : ST_SimCfg;         // параметры модели (ReadWrite в сборке имитации)
    stSimCmd        : ST_SimCmd;         // команды модели (ReadWrite в сборке имитации)
    stFaultInj      : ST_FaultInjection; // отказы (ReadWrite в сборке имитации)
    stSimSts        : ST_SimSts;         // Read
    xIoReady        : BOOL;              // входы GVL_IO действительны: реальный режим или модель опубликовала их (Read)
END_VAR
