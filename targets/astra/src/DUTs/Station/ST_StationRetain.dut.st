// Назначение: энергонезависимое состояние станции (GVL_Persist.stStationRetain): режим, способ
//             регулирования, следующий ведущий для чередования по кругу. Тип лежит в Persistent
//             Variables: не менять (новые данные — в резерве).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/DESIGN.md, раздел 3.1
{attribute 'qualified_only'}
TYPE ST_StationRetain :
STRUCT
    eMode       : E_StationMode := E_StationMode.Manual;      // пустой retain — «Ручной» (04 §3.2)
    eMethod     : E_ControlMethod := E_ControlMethod.Stepped;
    uiNextLead  : UINT := 1;                                  // Cyclic: следующий ведущий
    uiReserve   : UINT;
    audiReserve : ARRAY[0..7] OF UDINT;
END_STRUCT
END_TYPE
