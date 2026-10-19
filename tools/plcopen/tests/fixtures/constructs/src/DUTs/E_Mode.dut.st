// Режим устройства: перечисление с явными значениями и базовым типом
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_Mode :
(
    OutOfService := 0,  // выведено из работы
    Auto := 1,          // автоматический
    Manual := 2,        // ручной
    Local := 3          // местный
) INT;
END_TYPE
