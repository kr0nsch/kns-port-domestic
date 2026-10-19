// Состояние при выходе из подавления или вывода из работы: Shelved, если shelve ещё действует,
// иначе базовое — условие активно ? ActiveUnack (оператор увидит тревогу заново) : Normal
METHOD PROTECTED ReleaseState : E_AlarmState
