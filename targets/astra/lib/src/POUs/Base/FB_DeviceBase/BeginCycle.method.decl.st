// Шаг 1 цикла: время этого вызова и шаг времени ltDt. В первом вызове и при «времени назад»
// ltDt = 0: LTIME без знака, разность считается только при ltNow >= ltPrevCall
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED BeginCycle
