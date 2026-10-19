PickLead := 0;
IF xPreferComm THEN
    PickLead := PickLeadIn(xCommOnly := TRUE);
END_IF
IF PickLead = 0 THEN
    PickLead := PickLeadIn(xCommOnly := FALSE);
END_IF
