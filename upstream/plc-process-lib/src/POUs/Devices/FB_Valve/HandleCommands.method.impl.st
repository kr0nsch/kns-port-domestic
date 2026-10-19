IF stValveCmd.xClose OR stValveCmd.xOpen OR stValveCmd.xStop THEN
    IF stValveCmd.xClose THEN
        eCmdTgt := E_ValveState.Closed;
    ELSIF stValveCmd.xOpen THEN
        eCmdTgt := E_ValveState.Open;
    ELSE
        eCmdTgt := E_ValveState.Intermediate;
    END_IF
    IF NOT xRemote THEN
        eResCmd := E_CmdResult.RejectedMode;
    ELSIF eCmdTgt = E_ValveState.Intermediate THEN
        // стоп: только у электропривода; безопасен, поэтому без проверки Cfg и отказов
        IF NOT xMotorized THEN
            eResCmd := E_CmdResult.RejectedNotSupported;
        ELSIF xIlkAct THEN
            eResCmd := E_CmdResult.RejectedInterlock;
        ELSE
            eResCmd := E_CmdResult.Accepted;
        END_IF
    ELSIF NOT xCfgEverOk THEN
        eResCmd := E_CmdResult.RejectedCfg;
    ELSIF xFaultAny THEN
        eResCmd := E_CmdResult.RejectedFault;
    ELSIF xIlkAct THEN
        eResCmd := E_CmdResult.RejectedInterlock;
    ELSIF (eCmdTgt = E_ValveState.Open AND wPermMissOpen <> 0)
          OR (eCmdTgt = E_ValveState.Closed AND wPermMissClose <> 0)
    THEN
        eResCmd := E_CmdResult.RejectedPermit;
    ELSIF NOT xPowerOk THEN
        eResCmd := E_CmdResult.RejectedInhibit;
    ELSE
        eResCmd := E_CmdResult.Accepted;
    END_IF
    IF eResCmd = E_CmdResult.Accepted THEN
        // Auto -> Manual (хук: цель := текущее направление); в Manual режим не меняется
        SwitchRemoteMode(eNew := E_DeviceMode.Manual, stRetain := stValveRet);
        eManTarget := eCmdTgt;
    END_IF
    SetCmdResult(eResult := eResCmd);
END_IF
stValveCmd.xOpen := FALSE;
stValveCmd.xClose := FALSE;
stValveCmd.xStop := FALSE;
IF stValveCmd.xResetMaint THEN
    stValveRet.udiOpCountMaint := 0;
    stValveRet.udiOpTimeMaint_s := 0;
    SetCmdResult(eResult := E_CmdResult.Accepted);
    stValveCmd.xResetMaint := FALSE;
END_IF
