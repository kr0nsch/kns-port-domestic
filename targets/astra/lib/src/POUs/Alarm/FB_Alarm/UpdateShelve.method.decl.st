// Шаг 6 тела: shelve. Снятие командой Unshelve или по истечении срока (причина — в eShelveEnd),
// затем новый запрос Shelve (повторный отсчитывает срок заново; в OutOfService не принимается).
// Срок отсчитывается от команды независимо от наложенных состояний. Сбрасывает запросы Shelve и Unshelve
// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)
METHOD PROTECTED UpdateShelve
