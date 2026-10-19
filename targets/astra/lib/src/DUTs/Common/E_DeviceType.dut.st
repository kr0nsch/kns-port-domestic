// Назначение: тип устройства в stSts.stCommon.eDevType. SCADA по нему выбирает фейсплейт,
//             генератор карты Modbus проверяет, что по адресу блока лежит ожидаемое устройство.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/ARCHITECTURE.md, раздел «Общие типы»
{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_DeviceType :
(
    None         := 0,   // до первого вызова
    AnalogInput  := 1,
    DigitalInput := 2,
    Motor        := 3,
    MotorVfd     := 4,
    Valve        := 5,
    ControlValve := 6,
    Pid          := 7
) INT;
END_TYPE
