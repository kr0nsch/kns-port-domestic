// 1. Часы контура MainTask: перебазирование при смене ускорения — в начале цикла (DESIGN, раздел 10)
GVL_Time.fbClockMain.Update(rTimeScale := SEL(GVL_Sim.xSimulation, 1.0, GVL_Sim.stSimCfg.rTimeScale));
GVL_Time.lrMainNow_s := PL.F_LTimeToSec(ltIn := GVL_Time.fbClockMain.Now());

// 2. Первый цикл: признак имитации фиксируется при старте и дальше не меняется (решение D-02)
IF NOT xInitDone THEN
    GVL_Sim.xSimulation := GVL_Sim.xSimulationReq AND GVL_Const.SIM_ALLOWED;
    xInitDone := TRUE;
END_IF

// 2а. Входы GVL_IO действительны: в реальном режиме — с первого цикла (драйверы обновляют их до цикла задачи), в
//     имитации — после первого цикла модели: PlantModelTask ниже MainTask по приоритету, и первый цикл MainTask
//     видит нули (обрыв AI, НЗ-поплавки «сработали», нет напряжения). До этого PRG_Station и PRG_Devices не
//     выполняются (GVL_Sim.xIoReady); признак не снимается
IF NOT GVL_Sim.xIoReady THEN
    GVL_Sim.xIoReady := NOT GVL_Sim.xSimulation OR GVL_Sim.stSimSts.xRunning;
END_IF

// 3. Адаптеры ПЧ: регистры чтения → входы PL.FB_MotorVfd (имена GVL_IO у каждого насоса свои)
fbVfdP101.Decode(wStw := GVL_IO.wP101_STW, uiFact := GVL_IO.uiP101_FACT, xSlaveOk := GVL_IO.xMbOk_RS485_1_S1);
GVL_IO.xP101_CommOk := fbVfdP101.xCommOk;
GVL_IO.xP101_VfdReady := fbVfdP101.xReady;
GVL_IO.xP101_VfdRun := fbVfdP101.xRunning;
GVL_IO.xP101_VfdFault := fbVfdP101.xFault;
GVL_IO.rP101_SpeedAct_pct := fbVfdP101.rSpeedAct_pct;

fbVfdP102.Decode(wStw := GVL_IO.wP102_STW, uiFact := GVL_IO.uiP102_FACT, xSlaveOk := GVL_IO.xMbOk_RS485_1_S2);
GVL_IO.xP102_CommOk := fbVfdP102.xCommOk;
GVL_IO.xP102_VfdReady := fbVfdP102.xReady;
GVL_IO.xP102_VfdRun := fbVfdP102.xRunning;
GVL_IO.xP102_VfdFault := fbVfdP102.xFault;
GVL_IO.rP102_SpeedAct_pct := fbVfdP102.rSpeedAct_pct;

fbVfdP103.Decode(wStw := GVL_IO.wP103_STW, uiFact := GVL_IO.uiP103_FACT, xSlaveOk := GVL_IO.xMbOk_RS485_1_S3);
GVL_IO.xP103_CommOk := fbVfdP103.xCommOk;
GVL_IO.xP103_VfdReady := fbVfdP103.xReady;
GVL_IO.xP103_VfdRun := fbVfdP103.xRunning;
GVL_IO.xP103_VfdFault := fbVfdP103.xFault;
GVL_IO.rP103_SpeedAct_pct := fbVfdP103.rSpeedAct_pct;
