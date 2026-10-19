IF eState = E_ValveState.Opening OR eState = E_ValveState.Open THEN
    CurrentTarget := E_ValveState.Open;
ELSIF eState = E_ValveState.Closing OR eState = E_ValveState.Closed THEN
    CurrentTarget := E_ValveState.Closed;
ELSIF eState = E_ValveState.Reversing THEN
    CurrentTarget := eTarget;
ELSE
    CurrentTarget := E_ValveState.Intermediate;
END_IF
