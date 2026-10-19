// Назначение: состояние тревоги по ISA-18.2: четыре базовых состояния и три наложенных
//             (по старшинству OutOfService > SuppressedByDesign > Shelved). Модель состояний —
//             сверить с ANSI/ISA-18.2-2016.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Тревоги»
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_AlarmState :
(
    Normal             := 0,   // норма: условия нет, квитировано
    ActiveUnack        := 1,   // активна, не квитирована
    ActiveAck          := 2,   // активна, квитирована
    RtnUnack           := 3,   // вернулась в норму без квитирования
    Shelved            := 4,   // отложена оператором, с таймаутом
    SuppressedByDesign := 5,   // подавлена по условию (логикой)
    OutOfService       := 6    // выведена из работы вместе с устройством
) INT;
END_TYPE
