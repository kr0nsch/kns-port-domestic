// Шаги 7–8 тела: наложенные состояния по старшинству OutOfService > SuppressedByDesign > Shelved и
// базовый автомат ISA-18.2 (Normal, ActiveUnack, ActiveAck, RtnUnack). Не больше одного перехода
// за вызов; переход квитирования (шаг 5 тела) выполняется раньше
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED UpdateState
