// Назначение: состояние дискретного входа для HMI/SCADA. 30 байт, 15 регистров Modbus.
//             Значение и сырой сигнал — биты DI_STS_VALUE / DI_STS_RAW в stCommon.wStatus и выход
//             экземпляра xValue: полей BOOL в Sts нет.
// Автор:      kr0nsch
// Версия:     0.1.0
// Документ:   docs/fb/FB_DigitalInput.md
{attribute 'qualified_only'}
TYPE ST_DigitalInputSts :
STRUCT
    stCommon        : ST_DeviceSts;   // 0..27
    uiSubstRemain_s : UINT;           // 28: до автоматического снятия подмены, с; 0 — подмены нет
END_STRUCT
END_TYPE
