// Назначение: одна тревога по ISA-18.2. Четыре базовых состояния (Normal, ActiveUnack,
//             ActiveAck, RtnUnack) и три наложенных по старшинству OutOfService >
//             SuppressedByDesign > Shelved; приоритет, задержки появления и снятия (FB_Delay),
//             shelve с таймаутом, подавление по условию, вывод из работы. Каждый переход eState
//             увеличивает udiSeq и отправляет событие в GVL_Lib.itfAlarmSink (если приёмник задан).
//             Методы Ack, Shelve, Unshelve только ставят запрос: его выполняет ближайший вызов тела.
//             Модель состояний и повторное оповещение после shelve — сверить с ANSI/ISA-18.2-2016.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_Alarm.md
FUNCTION_BLOCK FB_Alarm IMPLEMENTS I_Alarm
VAR_INPUT
    xIn           : BOOL;            // условие тревоги (до задержек)
    xSuppress     : BOOL;            // подавление по условию (suppressed by design)
    xOutOfService : BOOL;            // вывод из работы (устройство в OutOfService)
    udiId         : UDINT;           // номер тревоги на объекте
    rValue        : REAL;            // значение процесса для события
    stCfg         : ST_AlarmCfg;     // параметры; 16 байт — копирование дешевле ссылки
    itfTime       : I_TimeSource;    // источник времени; 0 — встроенный fbSysTime
END_VAR
VAR_OUTPUT
    eState        : E_AlarmState := E_AlarmState.Normal;   // состояние ISA-18.2
    xActive       : BOOL;            // условие после задержек (независимо от наложенных состояний)
    xUnacked      : BOOL;            // eState = ActiveUnack OR RtnUnack
    xInList       : BOOL;            // ActiveUnack, ActiveAck или RtnUnack — показывать в списке тревог
    xShelved      : BOOL;            // shelve действует (даже если сверху подавление или OutOfService)
    tShelveRemain : TIME;            // остаток shelve; T#0S — shelve нет
    ltLastChange  : LTIME;           // время последнего перехода
    udiSeq        : UDINT;           // +1 на каждый переход eState (переполнение допустимо)
END_VAR
VAR
    fbDelay      : FB_Delay;         // задержки появления (tOnDelay) и снятия (tOffDelay)
    fbSysTime    : FB_SystemTime;    // запасной источник времени
    xAckReq      : BOOL;             // запрос Ack()
    xShelveReq   : BOOL;             // запрос Shelve()
    tShelveReq   : TIME;             // срок из запроса Shelve()
    xUnshelveReq : BOOL;             // запрос Unshelve()
    ltShelveEnd  : LTIME;            // конец действующего shelve
    // --- реализация (сверх контракта 10.1) ---
    ltNow        : LTIME;            // время этого вызова: отметка переходов и событий
    tShelveDur   : TIME;             // срок действующего shelve (после замены T#0S и обрезки)
    ePrioAct     : E_AlarmPriority := E_AlarmPriority.Medium;      // действующий приоритет
    eShelveEnd   : E_AlarmEventReason := E_AlarmEventReason.None;  // как закончился shelve в этом вызове
END_VAR
VAR_TEMP
    itfTimeAct   : I_TimeSource;     // действующий источник этого вызова
END_VAR
