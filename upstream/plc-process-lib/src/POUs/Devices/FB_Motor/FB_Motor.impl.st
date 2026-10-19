// Нормативный порядок тела устройства (docs/fb/FB_DeviceBase.md, контракт 9.4). FB_MotorVfd вызывает
// это тело через SUPER^(...) после записи точек расширения.

// 0. Первый вызов: слоты тревог и тип (FB_MotorVfd задаёт MotorVfd раньше — не затирать)
IF xFirstCall THEN
    uiAlarmCount := GVL_Const.MOT_ALARM_COUNT;
    IF eDevType = E_DeviceType.None THEN
        eDevType := E_DeviceType.Motor;
    END_IF
END_IF

// 1. Время. Старт ПЛК — останов для паузы tMinStop
BeginCycle();
IF xFirstCall THEN
    ltStopMark := ltNow;
    ltRunEntry := ltNow;
END_IF

// 2. Конфигурация (LKG). THIS^: переопределение FB_MotorVfd добавляет биты ПЧ
IF AcceptCfg(wErr := THIS^.CheckConfig(stCfgIn := stCfg)) THEN
    stCfgLkg := stCfg;
END_IF

// 2а. Обратная связь: из точки расширения или DI. Короткий провал недостоверной ОС удерживает xRunning (M-18);
//     без питания или после подтверждённого отказа связи (xCommFault) устаревшая ОС работу не означает — двигатель
//     считается остановленным: Running, бит RUNNING и счётчики по ней не идут (VFD-11)
IF xFbOverride THEN
    xFbNow := xFbOverrideValue;
ELSE
    xFbNow := xFbRun;
END_IF
xFbAssumedOff := stCfgLkg.xFbUsed AND xFbInvalid AND (NOT xPowerOk OR xCommFault);
xFbRegain := xFbStale AND NOT xFbInvalid;
xFbOn := stCfgLkg.xFbUsed AND NOT xFbInvalid AND xFbNow;
xFbOff := NOT stCfgLkg.xFbUsed OR (NOT xFbInvalid AND NOT xFbNow) OR xFbAssumedOff;
IF xFbAssumedOff AND NOT xFbStale THEN
    xFbStaleRun := xRunning;
END_IF
xFbStale := xFbAssumedOff OR (xFbStale AND xFbInvalid);
IF stCfgLkg.xFbUsed THEN
    IF NOT xFbInvalid THEN
        xRunning := xFbNow;
    ELSIF xFbAssumedOff THEN
        xRunning := FALSE;
    END_IF
ELSE
    // без ОС — по команде; уточняется после автомата состояний
    xRunning := xRunCmd;
END_IF

// 3. Reset: импульс xQReset на tResetPulse, окно tResetWindow снятия отказов, у которых ушла причина;
//    результат Accepted сразу, RejectedFault — если к концу окна отказ остался. Бит xReset сбросит RunAlarms
xResetNow := xResetReq OR stCmd.stCommon.xReset;
IF xResetNow THEN
    xResetWindow := TRUE;
    ltResetMark := ltNow;
    uiFirstOut := GVL_Const.NO_FIRST_OUT;
    // у отказов пуска и пропадания ОС нет длящейся причины: снимаются сразу
    xFltFailToStart := FALSE;
    xFltFbLost := FALSE;
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF
xQReset := FALSE;
IF xResetWindow THEN
    IF ltNow < ltResetMark THEN
        // время назад: окно и импульс отсчитываются заново (LTIME без знака)
        ltResetMark := ltNow;
    END_IF
    ltElapsed := ltNow - ltResetMark;
    IF NOT xRunning THEN
        xFltFailToStop := FALSE;
        xFltUncmd := FALSE;
    END_IF
    IF NOT (xExtFault OR xExtFaultAdd) THEN
        xFltExt := FALSE;
    END_IF
    xQReset := ltElapsed < TIME_TO_LTIME(stCfgLkg.tResetPulse);
    IF ltElapsed >= TIME_TO_LTIME(stCfgLkg.tResetWindow) THEN
        xResetWindow := FALSE;
        IF xFltFailToStart OR xFltFbLost OR xFltFailToStop OR xFltUncmd OR xFltExt THEN
            SetCmdResult(eResult := E_CmdResult.RejectedFault);
        END_IF
    END_IF
END_IF

// 4. Режим: Local поддерживается; вывод из работы — только когда механизм стоит: не Starting, Running,
//    Stopping и не работает по ОС (Fault с ОС — сварился контактор: вход в OOS снял бы FailToStop, M-23)
eRes := ProcessMode(xLocalSel := xLocal, xLocalSupported := TRUE,
                    xOosAllowed := NOT (eState = E_MotorState.Starting OR eState = E_MotorState.Running
                                        OR eState = E_MotorState.Stopping OR xRunning),
                    stCmd := stCmd.stCommon, stRetain := stRetain);
IF eRes <> E_CmdResult.None THEN
    SetCmdResult(eResult := eRes);
END_IF
xRemote := eMode = E_DeviceMode.Auto OR eMode = E_DeviceMode.Manual;

// 5. Блокировки, разрешения и условия пуска (13.5)
wIlkAct := wInterlock AND stCfgLkg.wInterlockMask;
xIlk := wIlkAct <> 0;
IF xIlk AND wIlkPrev = 0 AND eMode <> E_DeviceMode.OutOfService THEN
    // первопричина: младший бит при переходе действующих блокировок из 0 в ненулевое значение
    wScan := wIlkAct;
    uiBit := 0;
    WHILE (wScan AND 1) = 0 DO
        wScan := SHR(wScan, 1);
        uiBit := uiBit + 1;
    END_WHILE
    uiFirstOut := uiBit;
END_IF
wIlkPrev := wIlkAct;
IF NOT xIlk THEN
    xIlkTrip := FALSE;
END_IF
wPermMiss := stCfgLkg.wPermitMask AND NOT wPermit;
xPermitOk := wPermMiss = 0 AND NOT xStartBlockAdd;
xFaultAny := xFltFailToStart OR xFltFbLost OR xFltFailToStop OR xFltUncmd OR xFltExt
             OR (xCommFault AND eMode <> E_DeviceMode.OutOfService);
// пропадание напряжения — останов: от него отсчитывается tMinStop
IF NOT xPowerOk AND xPowerPrev THEN
    ltStopMark := ltNow;
END_IF
xPowerPrev := xPowerOk;
IF ltNow < ltStopMark THEN
    // время назад: пауза отсчитывается заново
    ltStopMark := ltNow;
END_IF
ltElapsed := ltNow - ltStopMark;
ltMinStop := TIME_TO_LTIME(stCfgLkg.tMinStop);
IF ltElapsed < ltMinStop THEN
    ltMinStopLeft := ltMinStop - ltElapsed;
ELSE
    ltMinStopLeft := LTIME#0S;
END_IF
uiStartsHour := fbStarts.Count(ltNow := ltNow);
xStartsLimit := stCfgLkg.uiMaxStartsPerHour > 0 AND uiStartsHour >= stCfgLkg.uiMaxStartsPerHour;
xInhibit := NOT xPowerOk OR ltMinStopLeft > LTIME#0S OR xStartsLimit;
xStartOk := xCfgEverOk AND NOT xFaultAny AND NOT xIlk AND xPermitOk AND NOT xInhibit;

// 6. Команды устройства: xStop старше xStart; счётчики ТО; PresetCounters()
IF stCmd.xStop THEN
    IF eMode = E_DeviceMode.Auto THEN
        // «Стоп» оператора в Auto: переход в Manual (хук: защёлка := xRunCmd) и останов
        SwitchRemoteMode(eNew := E_DeviceMode.Manual, stRetain := stRetain);
        xManualRun := FALSE;
        SetCmdResult(eResult := E_CmdResult.Accepted);
    ELSIF eMode = E_DeviceMode.Manual THEN
        xManualRun := FALSE;
        SetCmdResult(eResult := E_CmdResult.Accepted);
    ELSE
        SetCmdResult(eResult := E_CmdResult.RejectedMode);
    END_IF
ELSIF stCmd.xStart THEN
    IF eMode <> E_DeviceMode.Manual THEN
        SetCmdResult(eResult := E_CmdResult.RejectedMode);
    ELSIF xRunCmd THEN
        // уже работает: пуск подтверждается без проверки паузы
        xManualRun := TRUE;
        SetCmdResult(eResult := E_CmdResult.Accepted);
    ELSIF NOT xCfgEverOk THEN
        SetCmdResult(eResult := E_CmdResult.RejectedCfg);
    ELSIF xFaultAny THEN
        SetCmdResult(eResult := E_CmdResult.RejectedFault);
    ELSIF xIlk THEN
        SetCmdResult(eResult := E_CmdResult.RejectedInterlock);
    ELSIF NOT xPermitOk THEN
        SetCmdResult(eResult := E_CmdResult.RejectedPermit);
    ELSIF xInhibit THEN
        SetCmdResult(eResult := E_CmdResult.RejectedInhibit);
    ELSE
        xManualRun := TRUE;
        SetCmdResult(eResult := E_CmdResult.Accepted);
    END_IF
END_IF
stCmd.xStart := FALSE;
stCmd.xStop := FALSE;
IF stCmd.xResetMaint THEN
    stRetain.udiOpTimeMaint_s := 0;
    stRetain.udiOpCountMaint := 0;
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF
stCmd.xResetMaint := FALSE;
IF xPresetReq THEN
    stRetain.udiOpTime_s := udiPresetTime_s;
    stRetain.udiOpCount := udiPresetCount;
    xPresetReq := FALSE;
    SetCmdResult(eResult := E_CmdResult.Accepted);
END_IF

// 7. Автомат состояний (13.7). Принудительный останов без tMinRun: отказ, нет Cfg, блокировка;
//    нет напряжения — останов без отказа
xEnteredStarting := FALSE;
// старт ПЛК: подхват решается в первом вызове с достоверной ОС (у ПЧ с ОС по связи — когда связь
// появится; до этого контроль ОС приостановлен)
xAdoptNow := xAdoptPending AND NOT xFbInvalid;
IF xAdoptNow THEN
    xAdoptPending := FALSE;
END_IF
IF xRemote THEN
    // работающий по ОС двигатель подхватывается (Manual или запрос Auto), иначе — штатный останов
    IF xAdoptNow AND xFbOn THEN
        IF eMode = E_DeviceMode.Manual OR xAutoRun THEN
            eState := E_MotorState.Running;
            ltRunEntry := ltNow;
            IF eMode = E_DeviceMode.Manual THEN
                xManualRun := TRUE;
            END_IF
        ELSE
            eState := E_MotorState.Stopping;
        END_IF
    END_IF
    // нет напряжения — останов без отказа. ОС ещё есть (выбег; ПЧ пережил провал) — Stopping: после
    // восстановления питания торможение контролирует tFbStop, а не контроль самопроизвольного пуска (M-10)
    IF NOT xPowerOk THEN
        IF eState = E_MotorState.Starting OR eState = E_MotorState.Running OR eState = E_MotorState.Stopping THEN
            IF xFbOff THEN
                eState := E_MotorState.Stopped;
            ELSE
                eState := E_MotorState.Stopping;
            END_IF
        END_IF
        xManualRun := FALSE;
    END_IF
    // принудительный останов (нет Cfg, блокировка) снимает ручную защёлку: после снятия блокировки
    // в Manual двигатель сам не запускается
    xForceStop := NOT xCfgEverOk OR xIlk;
    IF xForceStop THEN
        xManualRun := FALSE;
    END_IF
    // запрос работы: Auto — xAutoRun, снятие ждёт tMinRun от входа в Running; Manual — защёлка
    IF eMode = E_DeviceMode.Auto THEN
        IF ltNow < ltRunEntry THEN
            ltRunEntry := ltNow;
        END_IF
        xRunReq := xAutoRun OR (eState = E_MotorState.Running
                                AND ltNow - ltRunEntry < TIME_TO_LTIME(stCfgLkg.tMinRun));
    ELSE
        xRunReq := xManualRun;
    END_IF
    IF xFaultAny THEN
        eState := E_MotorState.Fault;
        xManualRun := FALSE;
    ELSE
        IF eState = E_MotorState.Fault OR (xFbRegain AND eState = E_MotorState.Stopped) THEN
            // отказ снят (Reset или восстановилась связь с ПЧ) или ОС снова достоверна после «считался
            // остановленным» (VFD-11): состояние — по ОС
            IF xFbOff THEN
                eState := E_MotorState.Stopped;
            ELSIF xFbOn AND xRunReq AND NOT xForceStop AND xPowerOk THEN
                eState := E_MotorState.Running;
                ltRunEntry := ltNow;
            ELSE
                eState := E_MotorState.Stopping;
            END_IF
        END_IF
        // отложенный ручной пуск («Пуск» во время выбега, M-09): двигатель остановился, а условия пуска уже не
        // выполнены (пропало разрешение) — пуск отменяется вторым результатом, сам позже он не произойдёт (13.5)
        IF eState = E_MotorState.Stopped AND eMode = E_DeviceMode.Manual AND xManualRun AND NOT xStartOk THEN
            xManualRun := FALSE;
            xRunReq := FALSE;
            IF xPermitOk THEN
                SetCmdResult(eResult := E_CmdResult.RejectedInhibit);
            ELSE
                SetCmdResult(eResult := E_CmdResult.RejectedPermit);
            END_IF
        END_IF
        IF eState = E_MotorState.Stopped AND xRunReq AND xStartOk THEN
            eState := E_MotorState.Starting;
            xEnteredStarting := TRUE;
            xAdoptPending := FALSE;
            xFbStaleRun := FALSE;
            fbStarts.Register(ltNow := ltNow);
            uiFirstOut := GVL_Const.NO_FIRST_OUT;
        END_IF
        IF eState = E_MotorState.Starting THEN
            IF xForceStop OR NOT xRunReq THEN
                xIlkTrip := xIlkTrip OR xIlk;
                eState := E_MotorState.Stopping;
            ELSIF xFbOn OR NOT stCfgLkg.xFbUsed THEN
                eState := E_MotorState.Running;
                ltRunEntry := ltNow;
            END_IF
        ELSIF eState = E_MotorState.Running THEN
            IF xForceStop OR NOT xRunReq THEN
                xIlkTrip := xIlkTrip OR xIlk;
                eState := E_MotorState.Stopping;
            END_IF
        END_IF
        IF eState = E_MotorState.Stopping AND xFbOff THEN
            eState := E_MotorState.Stopped;
        END_IF
    END_IF
    xSupervise := stCfgLkg.xFbUsed AND NOT xFbInvalid AND xPowerOk;
ELSE
    // Local и OutOfService: выходы сняты, состояние следует ОС; в Local — отказ, если он есть
    IF xFaultAny THEN
        eState := E_MotorState.Fault;
    ELSIF xRunning THEN
        IF eState <> E_MotorState.Running THEN
            ltRunEntry := ltNow;
        END_IF
        eState := E_MotorState.Running;
    ELSE
        eState := E_MotorState.Stopped;
    END_IF
    xSupervise := FALSE;
END_IF

// 7а. Контроль ОС (Auto, Manual; приостановлен при xFbInvalid и без напряжения) и внешняя авария
//     (все режимы, кроме OutOfService). Задержки вызываются после переходов: отсчёт начинается в
//     вызове, в котором двигатель вошёл в состояние
fbStartSup(xIn := xSupervise AND eState = E_MotorState.Starting, tOnDelay := stCfgLkg.tFbStart,
           itfTime := itfTimeAct);
fbLossSup(xIn := xSupervise AND eState = E_MotorState.Running AND NOT xFbNow, tOnDelay := stCfgLkg.tFbLossFilter,
          itfTime := itfTimeAct);
// останов контролируется и после отключения отказом (M-20): ОС осталась после внешней аварии, FailToStart или
// FeedbackLost — команды нет, механизм не остановился (сварился контактор). UncommandedRun и отказ связи — нет:
// у первого причина и есть ОС без команды, второй снимается сам по восстановлении связи (13.7)
fbStopSup(xIn := xSupervise AND (eState = E_MotorState.Stopping
                                 OR (eState = E_MotorState.Fault AND xFbNow
                                     AND (xFltExt OR xFltFailToStart OR xFltFbLost))),
          tOnDelay := stCfgLkg.tFbStop, itfTime := itfTimeAct);
fbUncmdSup(xIn := xSupervise AND eState = E_MotorState.Stopped AND xFbNow AND NOT xAdoptNow,
           tOnDelay := stCfgLkg.tFbStart, itfTime := itfTimeAct);
fbExtSup(xIn := (xExtFault OR xExtFaultAdd) AND eMode <> E_DeviceMode.OutOfService,
         tOnDelay := stCfgLkg.tExtFaultFilter, itfTime := itfTimeAct);
IF fbStartSup.xOut THEN
    xFltFailToStart := TRUE;
END_IF
IF fbLossSup.xOut THEN
    xFltFbLost := TRUE;
END_IF
IF fbStopSup.xOut THEN
    xFltFailToStop := TRUE;
END_IF
IF fbUncmdSup.xOut THEN
    xFltUncmd := TRUE;
END_IF
IF fbExtSup.xOut THEN
    xFltExt := TRUE;
END_IF
xFaultAny := xFltFailToStart OR xFltFbLost OR xFltFailToStop OR xFltUncmd OR xFltExt
             OR (xCommFault AND eMode <> E_DeviceMode.OutOfService);
IF xFaultAny THEN
    // отказ: выходы сняты, ручная защёлка снята
    eState := E_MotorState.Fault;
    xManualRun := FALSE;
END_IF

// 7б. Выходы
xRunCmd := xRemote AND (eState = E_MotorState.Starting OR eState = E_MotorState.Running);
xQRun := xRunCmd;
IF NOT stCfgLkg.xFbUsed THEN
    xRunning := xRunCmd;
END_IF

// 8. Счётчики (13.8): шаг ltDt (не больше DT_ACCUM_MAX) идёт в накопитель, если двигатель работал в
//    прошлом вызове; целые секунды переносятся в stRetain. Фронт работы — пуск. Провал ОС в Running короче
//    tFbLossFilter (дребезг блок-контакта) — не останов и не новый пуск (M-21)
uliOneSecond := LTIME_TO_ULINT(LTIME#1S);
xRunCount := xRunning OR (eState = E_MotorState.Running AND fbLossSup.xTimingOn);
IF xRunCountPrev THEN
    IF ltDt > GVL_Const.DT_ACCUM_MAX THEN
        ltRunAcc := ltRunAcc + GVL_Const.DT_ACCUM_MAX;
    ELSE
        ltRunAcc := ltRunAcc + ltDt;
    END_IF
    udiWhole := ULINT_TO_UDINT(LTIME_TO_ULINT(ltRunAcc) / uliOneSecond);
    IF udiWhole > 0 THEN
        ltRunAcc := ltRunAcc - ULINT_TO_LTIME(UDINT_TO_ULINT(udiWhole) * uliOneSecond);
        stRetain.udiOpTime_s := stRetain.udiOpTime_s + udiWhole;
        stRetain.udiOpTimeMaint_s := stRetain.udiOpTimeMaint_s + udiWhole;
        udiRunCurrent_s := udiRunCurrent_s + udiWhole;
    END_IF
END_IF
// подхват после старта ПЛК и работа, найденная по вернувшейся ОС (двигатель работал до её устаревания, пуска ПЛК
// не было, VFD-11), — не пуск; пуск в том же вызове (без ОС) — пуск
IF xRunCount AND NOT xRunCountPrev
   AND (NOT (xAdoptNow OR (xFbRegain AND xFbStaleRun)) OR xEnteredStarting)
THEN
    stRetain.udiOpCount := stRetain.udiOpCount + 1;
    stRetain.udiOpCountMaint := stRetain.udiOpCountMaint + 1;
    udiRunCurrent_s := 0;
    IF NOT xRunCmd THEN
        // пуск без команды ПЛК (по месту): тоже пусковой ток — отметка в окне пусков
        fbStarts.Register(ltNow := ltNow);
    END_IF
END_IF
IF NOT xRunCount THEN
    udiRunCurrent_s := 0;
END_IF
xRunCountPrev := xRunCount;
IF xFbRegain THEN
    xFbStaleRun := FALSE;
END_IF
// пауза tMinStop отсчитывается от первого вызова без команды и без работы по ОС
IF xRunCmd OR xRunning OR xRunOrCmdPrev THEN
    ltStopMark := ltNow;
END_IF
xRunOrCmdPrev := xRunCmd OR xRunning;
// ТО
xMaintTime := stCfgLkg.udiMaintInterval_h > 0
              AND UDINT_TO_ULINT(stRetain.udiOpTimeMaint_s)
                  >= UDINT_TO_ULINT(stCfgLkg.udiMaintInterval_h) * UDINT_TO_ULINT(GVL_Const.S_PER_H);
xMaintCount := stCfgLkg.udiMaintStarts > 0 AND stRetain.udiOpCountMaint >= stCfgLkg.udiMaintStarts;

// 9. Тревоги (слоты 6 и 7 заполняет FB_MotorVfd до SUPER^)
axAlmCond[E_MotorAlarm.FailToStart] := xFltFailToStart;
axAlmCond[E_MotorAlarm.FeedbackLost] := xFltFbLost;
axAlmCond[E_MotorAlarm.FailToStop] := xFltFailToStop;
axAlmCond[E_MotorAlarm.UncommandedRun] := xFltUncmd;
axAlmCond[E_MotorAlarm.ExtFault] := xFltExt;
axAlmCond[E_MotorAlarm.InterlockTrip] := xIlkTrip;
RunAlarms(udiIdBase := stCfgLkg.udiAlarmIdBase, stCmd := stCmd.stCommon, astCfg := stCfgLkg.astAlarm);

// 10. Состояние. Запрет пуска показывается, пока двигатель стоит; остаток — с отметки этого вызова
xIdle := NOT xRunCmd AND NOT xRunning;
ltElapsed := ltNow - ltStopMark;
IF ltElapsed < ltMinStop THEN
    ltMinStopLeft := ltMinStop - ltElapsed;
ELSE
    ltMinStopLeft := LTIME#0S;
END_IF
uiStartsHour := fbStarts.Count(ltNow := ltNow);
ltFree := fbStarts.TimeToFree(ltNow := ltNow, uiMax := stCfgLkg.uiMaxStartsPerHour);
xStartsLimit := stCfgLkg.uiMaxStartsPerHour > 0 AND uiStartsHour >= stCfgLkg.uiMaxStartsPerHour;
xInhibit := NOT xPowerOk OR ltMinStopLeft > LTIME#0S OR xStartsLimit;
IF xInhibit AND xIdle THEN
    IF ltFree > ltMinStopLeft THEN
        uliRemain := LTIME_TO_ULINT(ltFree);
    ELSE
        uliRemain := LTIME_TO_ULINT(ltMinStopLeft);
    END_IF
    // секунды с округлением вверх, не больше UINT_MAX
    uliRemain := (uliRemain + uliOneSecond - 1) / uliOneSecond;
    IF uliRemain > UINT_TO_ULINT(GVL_Const.UINT_MAX) THEN
        stSts.uiInhibitRemain_s := GVL_Const.UINT_MAX;
    ELSE
        stSts.uiInhibitRemain_s := ULINT_TO_UINT(uliRemain);
    END_IF
ELSE
    stSts.uiInhibitRemain_s := 0;
END_IF

wFlt := SEL(xFltFailToStart, 0, GVL_Const.MOT_FLT_FAIL_TO_START)
        OR SEL(xFltFbLost, 0, GVL_Const.MOT_FLT_FEEDBACK_LOST)
        OR SEL(xFltFailToStop, 0, GVL_Const.MOT_FLT_FAIL_TO_STOP)
        OR SEL(xFltUncmd, 0, GVL_Const.MOT_FLT_UNCOMMANDED_RUN)
        OR SEL(xFltExt, 0, GVL_Const.MOT_FLT_EXT_FAULT)
        OR SEL(xCommFault AND eMode <> E_DeviceMode.OutOfService, 0, GVL_Const.MOT_FLT_COMM_LOSS);
wWrn := SEL(xMaintTime, 0, GVL_Const.MOT_WRN_MAINT_RUNTIME)
        OR SEL(xMaintCount, 0, GVL_Const.MOT_WRN_MAINT_STARTS)
        OR SEL(xStartsLimit, 0, GVL_Const.MOT_WRN_STARTS_LIMIT)
        OR SEL(xPowerOk, GVL_Const.MOT_WRN_POWER_LOST, 0)
        OR SEL(xIlk AND eMode = E_DeviceMode.Local, 0, GVL_Const.MOT_WRN_INTERLOCK_IN_LOCAL)
        OR SEL(xRemote AND stCfgLkg.xFbUsed AND (xFbInvalid OR NOT xPowerOk), 0, GVL_Const.MOT_WRN_FB_SUSPENDED)
        OR wWarningAdd;
IF wFlt <> 0 THEN
    eDevSt := E_Ne107Status.Failure;
ELSIF xMaintTime OR xMaintCount THEN
    eDevSt := E_Ne107Status.MaintenanceRequired;
ELSE
    eDevSt := E_Ne107Status.Good;
END_IF
eDevSt := F_Ne107Worst(eA := eDevSt, eB := eDevStatusAdd);
xAvailDev := eMode = E_DeviceMode.Auto AND wFlt = 0 AND NOT xIlk AND xPowerOk;
wLow := SEL(xRunning, 0, GVL_Const.MOT_STS_RUNNING)
        OR SEL(xRunCmd, 0, GVL_Const.MOT_STS_RUN_CMD)
        OR SEL(eState = E_MotorState.Starting, 0, GVL_Const.MOT_STS_STARTING)
        OR SEL(eState = E_MotorState.Stopping, 0, GVL_Const.MOT_STS_STOPPING)
        OR SEL(xIlk AND eMode <> E_DeviceMode.OutOfService, 0, GVL_Const.MOT_STS_INTERLOCKED)
        OR SEL(xPermitOk, GVL_Const.MOT_STS_PERMIT_MISSING, 0)
        OR SEL(xInhibit AND xIdle, 0, GVL_Const.MOT_STS_START_INHIBIT)
        OR SEL(xAvailDev AND xCfgEverOk, 0, GVL_Const.MOT_STS_AVAILABLE);

stSts.eState := eState;
stSts.wInterlock := wIlkAct;
stSts.wPermitMissing := wPermMiss;
stSts.uiFirstOut := uiFirstOut;
stSts.uiStartsLastHour := uiStartsHour;
stSts.rRunTime_h := LREAL_TO_REAL(UDINT_TO_LREAL(stRetain.udiOpTime_s) / UDINT_TO_LREAL(GVL_Const.S_PER_H));
stSts.udiStarts := stRetain.udiOpCount;
stSts.rRunTimeMaint_h := LREAL_TO_REAL(UDINT_TO_LREAL(stRetain.udiOpTimeMaint_s)
                                       / UDINT_TO_LREAL(GVL_Const.S_PER_H));
stSts.udiStartsMaint := stRetain.udiOpCountMaint;
stSts.udiRunCurrent_s := udiRunCurrent_s;
FinishCycle(eDevStatus := eDevSt, xAvailableDev := xAvailDev, wLow := wLow, wFaultBits := wFlt, wWarnBits := wWrn,
            stCommon := stSts.stCommon);

// 11. Значения для свойств I_Motor (свойства не читают stRetain, R2)
// «стоит»: нет ни команды работы (Starting — ещё не готов), ни работы по ОС
xReadyToStart := xAvailable AND xIdle AND xPermitOk AND NOT xInhibit;
udiRunSecondsMem := stRetain.udiOpTime_s;
udiStartsMem := stRetain.udiOpCount;
