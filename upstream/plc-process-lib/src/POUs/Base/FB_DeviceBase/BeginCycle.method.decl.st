// Шаг 1 цикла: время этого вызова и шаг времени ltDt. В первом вызове и при «времени назад»
// ltDt = 0: LTIME без знака, разность считается только при ltNow >= ltPrevCall
METHOD PROTECTED BeginCycle
