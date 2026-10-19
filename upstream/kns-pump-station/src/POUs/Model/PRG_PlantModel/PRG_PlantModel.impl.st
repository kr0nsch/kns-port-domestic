// Реальный режим: модели нет, входы GVL_IO пишут драйверы модулей и мастер Modbus
IF NOT GVL_Sim.xSimulation THEN
    GVL_Sim.stSimSts.xRunning := FALSE;
    RETURN;
END_IF

// 1. Часы модели: коэффициент ускорения — в начале цикла задачи
GVL_Time.fbClockModel.Update(rTimeScale := GVL_Sim.stSimCfg.rTimeScale);

// 2. Выходы ПЛК для модели (три явных блока: имена GVL_IO у каждого насоса свои)
axRun[1] := GVL_IO.xP101_RUN;
awCtw[1] := GVL_IO.wP101_CTW;
auiFref[1] := GVL_IO.uiP101_FREF;
axRun[2] := GVL_IO.xP102_RUN;
awCtw[2] := GVL_IO.wP102_CTW;
auiFref[2] := GVL_IO.uiP102_FREF;
axRun[3] := GVL_IO.xP103_RUN;
awCtw[3] := GVL_IO.wP103_CTW;
auiFref[3] := GVL_IO.uiP103_FREF;

// 3. Модель (сама сбрасывает импульсы stSimCmd и считает изменения stFaultInj)
fbPlant(itfTime := GVL_Time.fbClockModel, axRun := axRun, awCtw := awCtw, auiFref := auiFref,
        xV1Run := GVL_IO.xV1_RUN, rTimeScaleAct := GVL_Time.fbClockModel.Scale,
        stCfg := GVL_Sim.stSimCfg, stCmd := GVL_Sim.stSimCmd, stFault := GVL_Sim.stFaultInj);

// 4. Входы ПЛК: ST_PlantIo → одноимённые переменные GVL_IO
GVL_IO.rLT101_mA := fbPlant.stIo.rLT101_mA;
GVL_IO.rPT201_mA := fbPlant.stIo.rPT201_mA;
GVL_IO.rFT202_mA := fbPlant.stIo.rFT202_mA;
GVL_IO.rAT401_mA := fbPlant.stIo.rAT401_mA;
GVL_IO.rAT402_mA := fbPlant.stIo.rAT402_mA;
GVL_IO.xLS102 := fbPlant.stIo.xLS102;
GVL_IO.xLS103 := fbPlant.stIo.xLS103;
GVL_IO.xLS203 := fbPlant.stIo.xLS203;
GVL_IO.xES301 := fbPlant.stIo.xES301;
GVL_IO.xYS302 := fbPlant.stIo.xYS302;
GVL_IO.xYS303 := fbPlant.stIo.xYS303;
GVL_IO.xZS404 := fbPlant.stIo.xZS404;
GVL_IO.xYS405 := fbPlant.stIo.xYS405;
GVL_IO.xHS501 := fbPlant.stIo.xHS501;
GVL_IO.xHS502 := fbPlant.stIo.xHS502;
GVL_IO.xV1_RFB := fbPlant.stIo.xV1_RFB;
GVL_IO.xV1_FLT := fbPlant.stIo.xV1_FLT;

GVL_IO.xP101_RFB := fbPlant.stIo.xP101_RFB;
GVL_IO.xP101_FLT := fbPlant.stIo.xP101_FLT;
GVL_IO.xHS114 := fbPlant.stIo.xHS114;
GVL_IO.xTS112 := fbPlant.stIo.xTS112;
GVL_IO.xMS113 := fbPlant.stIo.xMS113;
GVL_IO.wP101_STW := fbPlant.stIo.wP101_STW;
GVL_IO.uiP101_FACT := fbPlant.stIo.uiP101_FACT;
GVL_IO.uiIT111 := fbPlant.stIo.uiIT111;
GVL_IO.uiP101_FCODE := fbPlant.stIo.uiP101_FCODE;

GVL_IO.xP102_RFB := fbPlant.stIo.xP102_RFB;
GVL_IO.xP102_FLT := fbPlant.stIo.xP102_FLT;
GVL_IO.xHS124 := fbPlant.stIo.xHS124;
GVL_IO.xTS122 := fbPlant.stIo.xTS122;
GVL_IO.xMS123 := fbPlant.stIo.xMS123;
GVL_IO.wP102_STW := fbPlant.stIo.wP102_STW;
GVL_IO.uiP102_FACT := fbPlant.stIo.uiP102_FACT;
GVL_IO.uiIT121 := fbPlant.stIo.uiIT121;
GVL_IO.uiP102_FCODE := fbPlant.stIo.uiP102_FCODE;

GVL_IO.xP103_RFB := fbPlant.stIo.xP103_RFB;
GVL_IO.xP103_FLT := fbPlant.stIo.xP103_FLT;
GVL_IO.xHS134 := fbPlant.stIo.xHS134;
GVL_IO.xTS132 := fbPlant.stIo.xTS132;
GVL_IO.xMS133 := fbPlant.stIo.xMS133;
GVL_IO.wP103_STW := fbPlant.stIo.wP103_STW;
GVL_IO.uiP103_FACT := fbPlant.stIo.uiP103_FACT;
GVL_IO.uiIT131 := fbPlant.stIo.uiIT131;
GVL_IO.uiP103_FCODE := fbPlant.stIo.uiP103_FCODE;

GVL_IO.rTT403 := fbPlant.stIo.rTT403;
GVL_IO.xMbOk_RS485_1_S1 := fbPlant.stIo.xMbOk_RS485_1_S1;
GVL_IO.xMbOk_RS485_1_S2 := fbPlant.stIo.xMbOk_RS485_1_S2;
GVL_IO.xMbOk_RS485_1_S3 := fbPlant.stIo.xMbOk_RS485_1_S3;
GVL_IO.xMbOk_RS485_2_S10 := fbPlant.stIo.xMbOk_RS485_2_S10;

// 5. Состояние модели для HMI, сценариев и PRG_Station
GVL_Sim.stSimSts := fbPlant.stSts;
