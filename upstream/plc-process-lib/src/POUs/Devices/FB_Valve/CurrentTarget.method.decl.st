// Цель, при которой арматура «не дёргается»: текущее направление движения или положение
// (Opening, Open — Open; Closing, Closed — Closed; Reversing — цель реверса); иначе Intermediate
// («никуда»). Безударный переход в Manual и старт ПЛК в Manual. Внутренний шаг устройства:
// PROTECTED (правило L5 контракта), имя зарезервировано для наследников
METHOD PROTECTED CurrentTarget : E_ValveState
