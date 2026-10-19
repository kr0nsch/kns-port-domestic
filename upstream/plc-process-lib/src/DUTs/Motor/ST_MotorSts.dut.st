// Назначение: состояние двигателя для HMI/SCADA (и для FB_MotorVfd). 68 байт, 34 регистра
//             Modbus: только 16- и 32-битные поля без скрытого выравнивания.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Motor.md
{attribute 'qualified_only'}
TYPE ST_MotorSts :
STRUCT
    stCommon          : ST_DeviceSts;   // 0..27; eDevType = MotorVfd — фейсплейт показывает блок ПЧ
    eState            : E_MotorState;   // 28
    wInterlock        : WORD;    // 30: действующие блокировки (wInterlock AND wInterlockMask)
    wPermitMissing    : WORD;    // 32: недостающие разрешения (wPermitMask AND NOT wPermit)
    uiFirstOut        : UINT;    // 34: номер бита первой сработавшей блокировки 0..15; NO_FIRST_OUT — нет
    uiInhibitRemain_s : UINT;    // 36: до снятия запрета пуска (пауза, лимит пусков), с, вверх, <= UINT_MAX
    uiStartsLastHour  : UINT;    // 38: пусков за скользящий час
    rRunTime_h        : REAL;    // 40: наработка всего, ч
    udiStarts         : UDINT;   // 44: пусков всего
    rRunTimeMaint_h   : REAL;    // 48: наработка с последнего ТО, ч
    udiStartsMaint    : UDINT;   // 52: пусков с последнего ТО
    rSpeedRef_pct     : REAL;    // 56: задание на ПЧ после ограничений и рампы, % (0 у прямого пуска)
    rSpeedAct_pct     : REAL;    // 60: фактическая скорость, % (0 у прямого пуска)
    udiRunCurrent_s   : UDINT;   // 64: текущая непрерывная работа, с; 0, пока стоит
END_STRUCT
END_TYPE
