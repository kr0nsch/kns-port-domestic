// Назначение: константы библиотеки. В логике нет «магических чисел» — только имена отсюда.
//             Внутри библиотеки обращение — GVL_Const.X, из приложения — PL.GVL_Const.X.
//             Маски битов слов состояния (тип WORD, значение = 2^бит) названы по правилу
//             <ПРЕФИКС>_<СЛОВО>_<ИМЯ>: префиксы DEV (общие), AI, DI, MOT, VLV, CV, PID; слова
//             STS (wStatus), FLT (wFault), WRN (wWarning), CFG (wCfgErr).
//             Новые константы устройства добавляются в конец блока этого устройства.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Константы и карты битов»
{attribute 'qualified_only'}
VAR_GLOBAL CONSTANT
    // --- NAMUR NE 43, ток 4–20 мА (границы — сверить с NE 43, A-02) ---
    NE43_FAIL_LOW_MA     : REAL := 3.6;            // I <= — отказ
    NE43_MEAS_LOW_MA     : REAL := 3.8;            // I < — вне диапазона снизу
    NE43_MEAS_HIGH_MA    : REAL := 20.5;           // I > — вне диапазона сверху
    NE43_FAIL_HIGH_MA    : REAL := 21.0;           // I >= — отказ
    MA_ZERO              : REAL := 4.0;            // ток нуля шкалы, мА
    MA_SPAN              : REAL := 16.0;           // диапазон тока, мА

    // --- числа и пределы ---
    PCT_FULL             : REAL := 100.0;          // 100 %
    REAL_SANE_MAX        : REAL := 1.0E30;         // |x| больше — мусор (например, перепутан порядок слов Modbus)
    AI_LOWCUT_MAX_PCT    : REAL := 20.0;           // предел rLowCut_pct
    REAL_EXP_MASK        : DWORD := 16#7F800000;   // биты экспоненты REAL (F_IsFinite)
    WORD_ALL             : WORD := 16#FFFF;        // все биты слова (проверка разрешений)
    WORD_LOW_BYTE        : WORD := 16#00FF;        // младший байт wStatus (FinishCycle)
    UINT_MAX             : UINT := 65535;          // предел счётчиков-секунд в Sts (uiInhibitRemain_s и т. п.)

    // --- время ---
    NS_PER_S             : LREAL := 1.0E9;         // нс в секунде (единица LTIME — нс)
    MS_PER_S             : LREAL := 1000.0;        // мс в секунде (единица TIME — мс)
    S_PER_H              : UDINT := 3600;          // с в часе
    DT_ACCUM_MAX         : LTIME := LTIME#10S;     // больший шаг времени не идёт в счётчики наработки

    // --- тревоги устройств ---
    DEV_ALARMS_MAX       : UINT := 8;              // слотов тревог в устройстве
    NO_FIRST_OUT         : UINT := 16#FFFF;        // первопричины нет (uiFirstOut)

    // --- окно пусков (FB_StartsWindow) ---
    STARTS_WINDOW_MAX    : UINT := 30;             // ёмкость окна = максимум uiMaxStartsPerHour
    STARTS_WINDOW        : LTIME := LTIME#1H;      // длина окна пусков

    // --- ПИД ---
    PID_DFILTER_N_MIN    : REAL := 2.0;            // допустимый rDFilterN, нижняя граница
    PID_DFILTER_N_MAX    : REAL := 50.0;           // допустимый rDFilterN, верхняя граница
    PID_DEADBAND_MAX_PCT : REAL := 10.0;           // предел зоны нечувствительности, %

    // --- параметры устройств вне Cfg (Cfg заморожена в 1.x, A-13; кандидаты в поля Cfg 2.0) ---
    VLV_UNSEAT_BYPASS    : TIME := T#2S;           // FB_Valve: страгивание с седла без контроля муфты
    CV_TIGHT_HYST_PCT    : REAL := 1.0;            // FB_ControlValve: гистерезис снятия плотного закрытия, %
    VFD_POWER_UP_DELAY   : TIME := T#10S;          // FB_MotorVfd: готовность ПЧ к обмену после возврата питания

    // --- число используемых слотов тревог по типам (uiAlarmCount в первом вызове) ---
    AI_ALARM_COUNT       : UINT := 6;              // FB_AnalogInput: HH, H, L, LL, Failure, OutOfRange
    DI_ALARM_COUNT       : UINT := 2;              // FB_DigitalInput: State, Failure
    MOT_ALARM_COUNT      : UINT := 8;              // FB_Motor (слоты 6–7 формирует только FB_MotorVfd)
    VLV_ALARM_COUNT      : UINT := 7;              // FB_Valve
    CV_ALARM_COUNT       : UINT := 4;              // FB_ControlValve
    PID_ALARM_COUNT      : UINT := 1;              // FB_PID: PvInvalid
END_VAR

// Общий старший байт wStatus — одинаковый у всех устройств
VAR_GLOBAL CONSTANT
    DEV_STS_MODE_AUTO    : WORD := 16#0100;        // бит 8: режим Auto (AI/DI: измерение)
    DEV_STS_MODE_MANUAL  : WORD := 16#0200;        // бит 9: режим Manual (AI/DI: подмена)
    DEV_STS_MODE_LOCAL   : WORD := 16#0400;        // бит 10: режим Local
    DEV_STS_MODE_OOS     : WORD := 16#0800;        // бит 11: выведено из работы
    DEV_STS_CFG_ERROR    : WORD := 16#1000;        // бит 12: wCfgErr <> 0 OR NOT xCfgEverOk
    DEV_STS_FAILURE      : WORD := 16#2000;        // бит 13: eNe107 = Failure
    DEV_STS_WARNING      : WORD := 16#4000;        // бит 14: wWarning <> 0 или eNe107 S, M
    DEV_STS_ALARM_UNACK  : WORD := 16#8000;        // бит 15: wAlmUnack <> 0
END_VAR

// FB_AnalogInput: младший байт wStatus, wFault, wWarning, wCfgErr
VAR_GLOBAL CONSTANT
    AI_STS_HH                 : WORD := 16#0001;   // бит 0: xHH
    AI_STS_H                  : WORD := 16#0002;   // бит 1: xH
    AI_STS_L                  : WORD := 16#0004;   // бит 2: xL
    AI_STS_LL                 : WORD := 16#0008;   // бит 3: xLL
    AI_STS_SIGNAL_FAIL        : WORD := 16#0010;   // бит 4: отказ сигнала подтверждён (xFail)
    AI_STS_OUT_OF_RANGE       : WORD := 16#0020;   // бит 5: вне диапазона подтверждено (xOor)
    AI_STS_FAIL_PENDING       : WORD := 16#0040;   // бит 6: значение удерживается до подтверждения отказа
    AI_STS_LOW_CUT            : WORD := 16#0080;   // бит 7: сработала отсечка малых значений

    AI_FLT_FAIL_LOW           : WORD := 16#0001;   // бит 0: I <= 3,6 мА
    AI_FLT_FAIL_HIGH          : WORD := 16#0002;   // бит 1: I >= 21,0 мА
    AI_FLT_CHANNEL            : WORD := 16#0004;   // бит 2: отказ канала
    AI_FLT_NOT_FINITE         : WORD := 16#0008;   // бит 3: NaN, ±Inf, |rIn| > REAL_SANE_MAX

    AI_WRN_UNDER_RANGE        : WORD := 16#0001;   // бит 0: 3,6 < I < 3,8 мА
    AI_WRN_OVER_RANGE         : WORD := 16#0002;   // бит 1: 20,5 < I < 21,0 мА
    AI_WRN_CLAMPED            : WORD := 16#0004;   // бит 2: значение ограничено шкалой (xClamp)

    AI_CFG_INPUT_TYPE         : WORD := 16#0001;   // бит 0: eInput вне перечисления
    AI_CFG_RANGE              : WORD := 16#0002;   // бит 1: rRangeLo_eu >= rRangeHi_eu или не конечны
    AI_CFG_LIMIT_ORDER        : WORD := 16#0004;   // бит 2: включённые уставки не строго LL < L < H < HH
    AI_CFG_LIMIT_OUT_OF_RANGE : WORD := 16#0008;   // бит 3: включённая уставка вне шкалы
    AI_CFG_HYST               : WORD := 16#0010;   // бит 4: гистерезис включённой уставки неверен
    AI_CFG_LOW_CUT            : WORD := 16#0020;   // бит 5: rLowCut_pct вне 0…AI_LOWCUT_MAX_PCT
    AI_CFG_FAIL_VALUE         : WORD := 16#0040;   // бит 6: eFailValue вне перечисления или rFailValue_eu не конечно
    AI_CFG_ALARM              : WORD := 16#0080;   // бит 7: приоритет тревоги вне перечисления
    AI_CFG_RAW_RANGE          : WORD := 16#0100;   // бит 8: eInput = Raw и rRawLo_cnt >= rRawHi_cnt или не конечны
END_VAR

// FB_DigitalInput: младший байт wStatus, wFault, wCfgErr (wWarning не используется)
VAR_GLOBAL CONSTANT
    DI_STS_VALUE              : WORD := 16#0001;   // бит 0: значение xValue
    DI_STS_RAW                : WORD := 16#0002;   // бит 1: сырой сигнал после инверсии, до задержек
    DI_STS_TIMING_ON          : WORD := 16#0004;   // бит 2: идёт задержка включения
    DI_STS_TIMING_OFF         : WORD := 16#0008;   // бит 3: идёт задержка отключения
    DI_STS_CHANNEL_FAULT      : WORD := 16#0010;   // бит 4: отказ канала
    DI_STS_ALARM_COND         : WORD := 16#0020;   // бит 5: условие слота State

    DI_FLT_CHANNEL            : WORD := 16#0001;   // бит 0: отказ канала

    DI_CFG_FAIL_VALUE         : WORD := 16#0001;   // бит 0: eFailValue вне перечисления
    DI_CFG_ALARM              : WORD := 16#0002;   // бит 1: приоритет тревоги вне перечисления
END_VAR

// FB_Motor и FB_MotorVfd: младший байт wStatus, wFault, wWarning, wCfgErr (биты 8–11 — ПЧ)
VAR_GLOBAL CONSTANT
    MOT_STS_RUNNING            : WORD := 16#0001;  // бит 0: работает
    MOT_STS_RUN_CMD            : WORD := 16#0002;  // бит 1: команда работы (xRunCmd)
    MOT_STS_STARTING           : WORD := 16#0004;  // бит 2: пуск, ждём ОС
    MOT_STS_STOPPING           : WORD := 16#0008;  // бит 3: останов, ждём пропадания ОС
    MOT_STS_INTERLOCKED        : WORD := 16#0010;  // бит 4: действует блокировка
    MOT_STS_PERMIT_MISSING     : WORD := 16#0020;  // бит 5: нет разрешения на пуск
    MOT_STS_START_INHIBIT      : WORD := 16#0040;  // бит 6: запрет пуска (пауза, лимит пусков, питание)
    MOT_STS_AVAILABLE          : WORD := 16#0080;  // бит 7: доступен автоматике

    MOT_FLT_FAIL_TO_START      : WORD := 16#0001;  // бит 0: нет ОС за tFbStart
    MOT_FLT_FEEDBACK_LOST      : WORD := 16#0002;  // бит 1: ОС пропала в работе
    MOT_FLT_FAIL_TO_STOP       : WORD := 16#0004;  // бит 2: ОС не пропала за tFbStop
    MOT_FLT_UNCOMMANDED_RUN    : WORD := 16#0008;  // бит 3: ОС без команды
    MOT_FLT_EXT_FAULT          : WORD := 16#0010;  // бит 4: внешняя авария
    MOT_FLT_COMM_LOSS          : WORD := 16#0020;  // бит 5: потеря связи с ПЧ (не фиксируется)

    MOT_WRN_MAINT_RUNTIME      : WORD := 16#0001;  // бит 0: ТО по наработке
    MOT_WRN_MAINT_STARTS       : WORD := 16#0002;  // бит 1: ТО по числу пусков
    MOT_WRN_SPEED_DEV          : WORD := 16#0004;  // бит 2: рассогласование скорости (ПЧ)
    MOT_WRN_STARTS_LIMIT       : WORD := 16#0008;  // бит 3: исчерпан лимит пусков в час
    MOT_WRN_POWER_LOST         : WORD := 16#0010;  // бит 4: нет напряжения
    MOT_WRN_INTERLOCK_IN_LOCAL : WORD := 16#0020;  // бит 5: блокировка в режиме Local
    MOT_WRN_COMM_LOSS          : WORD := 16#0040;  // бит 6: потеря связи с ПЧ при xCommLossIsFault = FALSE
    MOT_WRN_FB_SUSPENDED       : WORD := 16#0080;  // бит 7: контроль ОС приостановлен
    MOT_WRN_SPEED_SP_INVALID   : WORD := 16#0100;  // бит 8: задание скорости не конечно, удерживается (ПЧ)

    MOT_CFG_FB_TIMES           : WORD := 16#0001;  // бит 0: xFbUsed и tFbStart или tFbStop = T#0S
    MOT_CFG_STARTS_LIMIT       : WORD := 16#0002;  // бит 1: uiMaxStartsPerHour > STARTS_WINDOW_MAX
    MOT_CFG_RESET              : WORD := 16#0004;  // бит 2: tResetWindow = T#0S или tResetPulse > tResetWindow
    MOT_CFG_ALARM              : WORD := 16#0008;  // бит 3: приоритет тревоги вне перечисления
    MOT_CFG_VFD_SPEED_LIMITS   : WORD := 16#0100;  // бит 8: пределы скорости ПЧ неверны
    MOT_CFG_VFD_RAMP           : WORD := 16#0200;  // бит 9: рампа < 0 или не конечна
    MOT_CFG_VFD_COMM           : WORD := 16#0400;  // бит 10: tCommLoss = T#0S
    MOT_CFG_VFD_SPEED_DEV      : WORD := 16#0800;  // бит 11: параметры рассогласования скорости неверны
END_VAR

// FB_Valve: младший байт wStatus, wFault, wWarning, wCfgErr
VAR_GLOBAL CONSTANT
    VLV_STS_OPENED             : WORD := 16#0001;  // бит 0: положение «открыто»
    VLV_STS_CLOSED             : WORD := 16#0002;  // бит 1: положение «закрыто»
    VLV_STS_OPENING            : WORD := 16#0004;  // бит 2: открывается
    VLV_STS_CLOSING            : WORD := 16#0008;  // бит 3: закрывается
    VLV_STS_INTERLOCKED        : WORD := 16#0010;  // бит 4: действует блокировка
    VLV_STS_PERMIT_MISSING     : WORD := 16#0020;  // бит 5: нет разрешения для текущего направления
    VLV_STS_TORQUE             : WORD := 16#0040;  // бит 6: муфта сработала
    VLV_STS_AVAILABLE          : WORD := 16#0080;  // бит 7: доступна автоматике

    VLV_FLT_FAIL_TO_OPEN       : WORD := 16#0001;  // бит 0: не открылась за tTravel
    VLV_FLT_FAIL_TO_CLOSE      : WORD := 16#0002;  // бит 1: не закрылась за tTravel
    VLV_FLT_BOTH_LIMITS        : WORD := 16#0004;  // бит 2: оба концевика (не фиксируется)
    VLV_FLT_POSITION_LOST      : WORD := 16#0008;  // бит 3: уход с концевика
    VLV_FLT_TORQUE_TRIP        : WORD := 16#0010;  // бит 4: муфта в ходе
    VLV_FLT_EXT_FAULT          : WORD := 16#0020;  // бит 5: авария привода

    VLV_WRN_MAINT_CYCLES       : WORD := 16#0001;  // бит 0: ТО по числу циклов
    VLV_WRN_POWER_LOST         : WORD := 16#0002;  // бит 1: нет напряжения
    VLV_WRN_INTERLOCK_IN_LOCAL : WORD := 16#0004;  // бит 2: блокировка в режиме Local
    VLV_WRN_POSITION_BY_TIME   : WORD := 16#0008;  // бит 3: положение по времени хода (нет концевика)
    VLV_WRN_POSITION_UNKNOWN   : WORD := 16#0010;  // бит 4: положение неизвестно

    VLV_CFG_TYPE               : WORD := 16#0001;  // бит 0: eType вне перечисления
    VLV_CFG_TRAVEL             : WORD := 16#0002;  // бит 1: tTravel = T#0S
    VLV_CFG_SAFE_POS           : WORD := 16#0004;  // бит 2: eSafePos вне перечисления или Stay у соленоида
    VLV_CFG_TORQUE             : WORD := 16#0008;  // бит 3: настройки муфты противоречат типу
    VLV_CFG_REVERSE            : WORD := 16#0010;  // бит 4: Motorized и tReverse = T#0S
    VLV_CFG_RESET              : WORD := 16#0020;  // бит 5: tResetWindow = T#0S
    VLV_CFG_ALARM              : WORD := 16#0040;  // бит 6: приоритет тревоги вне перечисления
END_VAR

// FB_ControlValve: младший байт wStatus, wFault, wWarning, wCfgErr
VAR_GLOBAL CONSTANT
    CV_STS_AT_SETPOINT         : WORD := 16#0001;  // бит 0: |out − fb| <= rDevMax_pct
    CV_STS_RAMPING             : WORD := 16#0002;  // бит 1: идёт рампа
    CV_STS_LIMITED_MIN         : WORD := 16#0004;  // бит 2: задание ограничено снизу
    CV_STS_LIMITED_MAX         : WORD := 16#0008;  // бит 3: задание ограничено сверху
    CV_STS_INTERLOCKED         : WORD := 16#0010;  // бит 4: действует блокировка
    CV_STS_TIGHT_SHUT          : WORD := 16#0020;  // бит 5: плотное закрытие
    CV_STS_SAFE_POS            : WORD := 16#0040;  // бит 6: выход принудительно в rSafePos_pct
    CV_STS_AVAILABLE           : WORD := 16#0080;  // бит 7: доступен автоматике

    CV_FLT_DEVIATION           : WORD := 16#0001;  // бит 0: рассогласование (при xDevIsFault)
    CV_FLT_POSITIONER          : WORD := 16#0002;  // бит 1: отказ позиционера (не фиксируется)

    CV_WRN_DEVIATION           : WORD := 16#0001;  // бит 0: рассогласование
    CV_WRN_FB_INVALID          : WORD := 16#0002;  // бит 1: ОС положения недостоверна
    CV_WRN_SP_INVALID          : WORD := 16#0004;  // бит 2: задание не конечно, удерживается

    CV_CFG_LIMITS              : WORD := 16#0001;  // бит 0: пределы задания неверны
    CV_CFG_RATE                : WORD := 16#0002;  // бит 1: скорость < 0 или не конечна
    CV_CFG_SAFE_POS            : WORD := 16#0004;  // бит 2: rSafePos_pct вне 0…100 или не конечно
    CV_CFG_DEVIATION           : WORD := 16#0008;  // бит 3: xFbUsed и неверные rDevMax_pct или tDev
    CV_CFG_TIGHT_SHUT          : WORD := 16#0010;  // бит 4: rTightShut_pct < 0 или >= rOutMax_pct
    CV_CFG_FAULT_ACTION        : WORD := 16#0020;  // бит 5: eFaultAction вне перечисления
    CV_CFG_ALARM               : WORD := 16#0040;  // бит 6: приоритет тревоги вне перечисления
END_VAR

// FB_PID: младший байт wStatus, wFault, wWarning, wCfgErr
VAR_GLOBAL CONSTANT
    PID_STS_SAT_HIGH           : WORD := 16#0001;  // бит 0: выход на верхнем пределе
    PID_STS_SAT_LOW            : WORD := 16#0002;  // бит 1: выход на нижнем пределе
    PID_STS_SP_RAMPING         : WORD := 16#0004;  // бит 2: идёт рампа задания
    PID_STS_IN_DEADBAND        : WORD := 16#0008;  // бит 3: ошибка в зоне нечувствительности
    PID_STS_PV_FAIL            : WORD := 16#0010;  // бит 4: PV недостоверна
    PID_STS_DT_GAP             : WORD := 16#0020;  // бит 5: шаг инициализации (разрыв времени)
    PID_STS_TRACKING           : WORD := 16#0040;  // бит 6: слежение (xTrack)
    PID_STS_OUT_RATE_LIMITED   : WORD := 16#0080;  // бит 7: выход ограничен по скорости

    PID_FLT_PV_INVALID         : WORD := 16#0001;  // бит 0: PV недостоверна в Auto

    PID_WRN_DT_GAP             : WORD := 16#0001;  // бит 0: разрыв времени, шаг пропущен
    PID_WRN_SP_INVALID         : WORD := 16#0002;  // бит 1: задание не конечно, удерживается

    PID_CFG_ACTION             : WORD := 16#0001;  // бит 0: eAction вне перечисления
    PID_CFG_KP                 : WORD := 16#0002;  // бит 1: rKp <= 0 или не конечно
    PID_CFG_TI_TD              : WORD := 16#0004;  // бит 2: rTi_s < 0 или rTd_s < 0
    PID_CFG_DFILTER            : WORD := 16#0008;  // бит 3: rTd_s > 0 и rDFilterN вне допустимого
    PID_CFG_TT                 : WORD := 16#0010;  // бит 4: rTt_s < 0
    PID_CFG_PV_RANGE           : WORD := 16#0020;  // бит 5: rPvMin_eu >= rPvMax_eu
    PID_CFG_SP_RANGE           : WORD := 16#0040;  // бит 6: rSpMin_eu > rSpMax_eu
    PID_CFG_OUT_RANGE          : WORD := 16#0080;  // бит 7: пределы выхода неверны
    PID_CFG_DEADBAND           : WORD := 16#0100;  // бит 8: rDeadband_pct вне 0…PID_DEADBAND_MAX_PCT
    PID_CFG_RATES              : WORD := 16#0200;  // бит 9: rSpRate_ups < 0 или rOutRate_pctps < 0
    PID_CFG_SAMPLE             : WORD := 16#0400;  // бит 10: tDtMax = T#0S или tSample >= tDtMax
    PID_CFG_PV_FAIL            : WORD := 16#0800;  // бит 11: ePvFailAction или rSafeOut_pct неверны
    PID_CFG_ALARM              : WORD := 16#1000;  // бит 12: приоритет тревоги вне перечисления
END_VAR
