// Подачи насосов при напоре rHead_m (в arQ): √((H0·s² − H)/k) для насосов, которые могут подавать
// и открывают обратный клапан; результат — сумма
METHOD PRIVATE FlowsAt : REAL
VAR_INPUT
    rHead_m : REAL;         // напор сети
END_VAR
VAR
    uiJ : UINT;             // индекс насоса
END_VAR
