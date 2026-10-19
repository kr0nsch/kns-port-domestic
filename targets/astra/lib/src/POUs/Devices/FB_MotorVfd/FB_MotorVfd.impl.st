// Нормативный порядок (контракт 14.2): источник времени, точки расширения, тело FB_Motor, задание.

// 0. Источник времени этого вызова: BeginCycle выполнится позже, внутри тела FB_Motor, а вложенные
//    FB_Delay ниже вызываются раньше — иначе первый отсчёт шёл бы от системного времени
ResolveTime();

// 1. Точки расширения FB_Motor. Параметры ПЧ — по LKG прошлого вызова; в первом вызове LKG ещё не
//    принята, и, если stCfg корректна, берётся она: иначе выбор источника ОС (xFbFromComm) в первом
//    вызове шёл бы по умолчаниям и подхват работающего двигателя ошибся бы
stVfdCfgUse := stCfgLkg.stVfd;
IF xFirstCall THEN
    IF THIS^.CheckConfig(stCfgIn := stCfg) = 0 THEN
        stVfdCfgUse := stCfg.stVfd;
    END_IF
END_IF
xVfdCommValid := xCommOk AND F_IsFinite(rIn := rSpeedAct_pct);
// питание ПЧ: без напряжения и VFD_POWER_UP_DELAY после его возврата (ПЧ загружается) потеря связи — не отказ:
// пропадание питания станции — останов без отказа (13.7), а не отказ связи каждого ПЧ (VFD-12). После старта ПЛК
// при поданном питании ПЧ считается загруженным
fbVfdPowerUp(xIn := xPowerOk, tOnDelay := GVL_Const.VFD_POWER_UP_DELAY, itfTime := itfTimeAct);
IF xFirstCall THEN
    fbVfdPowerUp.Preset(xValue := xPowerOk);
END_IF
xVfdNoPowerComm := NOT xVfdCommValid AND NOT fbVfdPowerUp.xOut;
fbVfdCommLoss(xIn := NOT xVfdCommValid AND fbVfdPowerUp.xOut, tOnDelay := stVfdCfgUse.tCommLoss,
              itfTime := itfTimeAct);
xFbOverride := stVfdCfgUse.xFbFromComm;
xFbOverrideValue := xVfdRunning AND xVfdCommValid;
// контроль ОС приостанавливается с первого пропущенного ответа, а не после tCommLoss
xFbInvalid := stVfdCfgUse.xFbFromComm AND NOT xVfdCommValid;
xCommFault := fbVfdCommLoss.xOut AND stVfdCfgUse.xCommLossIsFault;
// слово состояния достоверно только при связи
xExtFaultAdd := xVfdFault AND xVfdCommValid;
xStartBlockAdd := xVfdCommValid AND NOT xVfdReady;
eDevType := E_DeviceType.MotorVfd;
// фактическая скорость для Sts и SpeedAct — конечная (NaN из Modbus — 0.0, R6)
rVfdSpeedAct_pct := SEL(F_IsFinite(rIn := rSpeedAct_pct), 0.0, rSpeedAct_pct);
// рассогласование: задание прошлого вызова (рампа завершена) против фактической скорости этого
xVfdSpeedDevCond := stVfdCfgUse.rSpeedDev_pct > 0.0 AND eState = E_MotorState.Running AND xVfdRampDone
                    AND xVfdCommValid AND ABS(rSpeedRef_pct - rSpeedAct_pct) > stVfdCfgUse.rSpeedDev_pct;
fbVfdSpeedDev(xIn := xVfdSpeedDevCond, tOnDelay := stVfdCfgUse.tSpeedDev, itfTime := itfTimeAct);
xVfdCommWarn := fbVfdCommLoss.xOut AND NOT stVfdCfgUse.xCommLossIsFault AND eMode <> E_DeviceMode.OutOfService;
// предупреждение COMM_LOSS — и как сведение: связи нет без питания или пока ПЧ загружается (без NE 107 S)
// цель текущего режима — для предупреждения «задание не конечно» в этом же вызове
IF eMode = E_DeviceMode.Auto THEN
    xVfdTargetOk := F_IsFinite(rIn := rSpeedSpAuto_pct);
ELSIF eMode = E_DeviceMode.Manual THEN
    xVfdTargetOk := F_IsFinite(rIn := stCmd.rSpeedSp_pct);
ELSE
    xVfdTargetOk := TRUE;
END_IF
wWarningAdd := SEL(fbVfdSpeedDev.xOut, 0, GVL_Const.MOT_WRN_SPEED_DEV)
               OR SEL(xVfdCommWarn OR (xVfdNoPowerComm AND eMode <> E_DeviceMode.OutOfService), 0,
                      GVL_Const.MOT_WRN_COMM_LOSS)
               OR SEL(xVfdTargetOk, GVL_Const.MOT_WRN_SPEED_SP_INVALID, 0);
IF fbVfdSpeedDev.xOut OR xVfdCommWarn THEN
    eDevStatusAdd := E_Ne107Status.OutOfSpecification;
ELSE
    eDevStatusAdd := E_Ne107Status.Good;
END_IF
axAlmCond[E_MotorAlarm.CommLoss] := fbVfdCommLoss.xOut;
axAlmCond[E_MotorAlarm.SpeedDeviation] := fbVfdSpeedDev.xOut;
arAlmValue[E_MotorAlarm.SpeedDeviation] := rVfdSpeedAct_pct;

// 2. Тело FB_Motor над теми же структурами: все VAR_IN_OUT явно (SUPER^(); — ошибка C0039)
SUPER^(stCmd := stCmd, stRetain := stRetain, stCfg := stCfg);

// 3. Задание скорости (14.3). После SUPER^ режим, eState, xRunCmd, xEnteredStarting и ltDt — этого вызова. Состояние
//    рампы — LREAL (VFD-13): приращение медленной рампы при коротком цикле не теряется округлением до REAL
lrVfdDt_s := F_LTimeToSec(ltIn := ltDt);
// предустановки ждут связи: пуск (rSpeedMin, VFD-10) и подхват — команда работы появилась без входа в Starting
// (работающий ПЧ после старта ПЛК, выход из отказа, возврат из Local): задание — от фактической скорости (VFD-09)
xVfdStartPending := (xVfdStartPending OR xEnteredStarting) AND xRunCmd;
xVfdPickPending := (xVfdPickPending OR (xRunCmd AND NOT xVfdRunCmdPrev AND NOT xEnteredStarting)) AND xRunCmd
                   AND NOT xVfdStartPending;
xVfdRunCmdPrev := xRunCmd;
IF xVfdPickPending AND xVfdCommValid AND eMode = E_DeviceMode.Manual AND xCfgEverOk THEN
    // Manual: задание оператора (не энергонезависимо, после старта 0) := фактическая скорость — без торможения
    stCmd.rSpeedSp_pct := LIMIT(stCfgLkg.stVfd.rSpeedMin_pct, rSpeedAct_pct, stCfgLkg.stVfd.rSpeedMax_pct);
END_IF
IF eMode = E_DeviceMode.Auto THEN
    rVfdTarget_pct := rSpeedSpAuto_pct;
ELSIF eMode = E_DeviceMode.Manual THEN
    rVfdTarget_pct := stCmd.rSpeedSp_pct;
ELSE
    rVfdTarget_pct := rSpeedAct_pct;
END_IF
xVfdTargetOk := F_IsFinite(rIn := rVfdTarget_pct);
IF xVfdTargetOk THEN
    rVfdTargetLim_pct := LIMIT(stCfgLkg.stVfd.rSpeedMin_pct, rVfdTarget_pct, stCfgLkg.stVfd.rSpeedMax_pct);
END_IF
IF NOT xCfgEverOk THEN
    // безопасное состояние без корректной Cfg
    lrVfdRef_pct := 0.0;
ELSIF xVfdCommValid THEN
    // (связь потеряна — задание удерживается: передать его всё равно нельзя)
    IF xRunCmd THEN
        IF xVfdStartPending THEN
            // рампа начинается с rSpeedMin_pct; без ограничения роста — сразу к цели
            IF stCfgLkg.stVfd.rRampUp_pctps > 0.0 OR NOT xVfdTargetOk THEN
                lrVfdRef_pct := REAL_TO_LREAL(stCfgLkg.stVfd.rSpeedMin_pct);
            ELSE
                lrVfdRef_pct := REAL_TO_LREAL(rVfdTargetLim_pct);
            END_IF
            xVfdStartPending := FALSE;
        ELSIF xVfdPickPending THEN
            // подхват: задание — фактическая скорость в пределах, без провала к 0 и рампы с нуля
            lrVfdRef_pct := REAL_TO_LREAL(LIMIT(stCfgLkg.stVfd.rSpeedMin_pct, rSpeedAct_pct,
                                                stCfgLkg.stVfd.rSpeedMax_pct));
            xVfdPickPending := FALSE;
        ELSIF xVfdTargetOk THEN
            lrVfdRef_pct := F_RateLimitLr(lrCurrent := lrVfdRef_pct, rTarget := rVfdTargetLim_pct,
                                          rRateUp_ups := stCfgLkg.stVfd.rRampUp_pctps,
                                          rRateDown_ups := stCfgLkg.stVfd.rRampDown_pctps, lrDt_s := lrVfdDt_s);
        END_IF
    ELSIF eMode = E_DeviceMode.Auto OR eMode = E_DeviceMode.Manual THEN
        // нет команды работы: 0 (торможение — рампой ПЧ)
        lrVfdRef_pct := 0.0;
    ELSIF xVfdTargetOk THEN
        // Local, OutOfService: задание следит за фактической скоростью — возврат без рывка
        lrVfdRef_pct := REAL_TO_LREAL(rVfdTarget_pct);
    END_IF
END_IF
rSpeedRef_pct := LREAL_TO_REAL(lrVfdRef_pct);
// рампа завершена: задание не ниже и не выше цели (для контроля рассогласования в следующем вызове)
xVfdRampDone := xRunCmd AND xVfdTargetOk
                AND NOT (rSpeedRef_pct < rVfdTargetLim_pct OR rSpeedRef_pct > rVfdTargetLim_pct);

// 4. Слежение задания оператора: Auto — цель в пределах; Manual — пределы и запись обратно;
//    Local, OutOfService — фактическая скорость. Не конечное значение не пишется
IF eMode = E_DeviceMode.Auto OR eMode = E_DeviceMode.Manual THEN
    IF xVfdTargetOk THEN
        stCmd.rSpeedSp_pct := rVfdTargetLim_pct;
    END_IF
ELSIF xVfdTargetOk THEN
    stCmd.rSpeedSp_pct := rVfdTarget_pct;
END_IF

// 5. Состояние ПЧ
xSpeedAutoActive := eMode = E_DeviceMode.Auto AND eState = E_MotorState.Running AND stSts.stCommon.wFault = 0;
stSts.rSpeedRef_pct := rSpeedRef_pct;
stSts.rSpeedAct_pct := rVfdSpeedAct_pct;
