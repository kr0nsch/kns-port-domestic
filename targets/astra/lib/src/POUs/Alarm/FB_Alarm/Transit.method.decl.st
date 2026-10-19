// Переход в состояние eNew: udiSeq + 1, отметка времени и событие в GVL_Lib.itfAlarmSink.
// Все переходы ФБ проходят здесь, в порядке шагов тела. Значение процесса в событии всегда конечно:
// NaN и ±Inf (PV из Modbus) — 0.0 (R6). Ответ приёмника (FALSE — переполнен) ФБ
// не повторяет. Внутренний шаг ФБ: PROTECTED, а не PRIVATE (правило L5 контракта)
METHOD PROTECTED Transit
VAR_INPUT
    eNew    : E_AlarmState;          // новое состояние
    eReason : E_AlarmEventReason;    // причина перехода
END_VAR
VAR
    stEvent : ST_AlarmEvent;         // событие для приёмника
END_VAR
