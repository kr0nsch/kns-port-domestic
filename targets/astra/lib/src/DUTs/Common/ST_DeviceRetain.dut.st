// Назначение: энергонезависимые данные устройства. Приложение размещает переменную этого
//             типа в объекте Persistent Variables, по переменной на устройство (st<TAG>Retain).
//             Объявление заморожено целиком, включая имена полей: любое изменение типа
//             переинициализирует persistent-переменную (A-13). Новые данные 1.x — только в
//             элементы audiReserve без переименования. SIZEOF = 36 (Control Win V3, 32 бит).
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Энергонезависимые данные»
{attribute 'qualified_only'}
TYPE ST_DeviceRetain :
STRUCT
    eRemoteMode      : E_DeviceMode := E_DeviceMode.Manual;   // последний дистанционный режим (Auto/Manual)
    xOutOfService    : BOOL;                     // выведено из работы оператором
    udiOpTime_s      : UDINT;                    // наработка всего, с (двигатель — работа; задвижка — ход)
    udiOpCount       : UDINT;                    // операций всего (двигатель — пуски; арматура — циклы)
    udiOpTimeMaint_s : UDINT;                    // наработка с последнего ТО, с
    udiOpCountMaint  : UDINT;                    // операций с последнего ТО
    audiReserve      : ARRAY[0..3] OF UDINT;     // резерв: новые поля без смены раскладки
END_STRUCT
END_TYPE
