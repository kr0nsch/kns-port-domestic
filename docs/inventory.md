# Инвентаризация возможностей CODESYS: флагман и библиотека

> Файл создаёт `tools/inventory.py` по настройкам `tools/inventory.toml`; вручную не правится.
> Повторить — `python tools/inventory.py` (README, раздел «Инвентаризация возможностей CODESYS»).
> Данные для автоматизации — `docs/inventory.json`.

Цель переноса: Astra.IDE 1.7.2.x (РегЛаб), ПЛК REGUL R500/R400, рантайм REGULRTS. Риск и ссылки (факты F, риски R, пункты чек-листа) — из: исследование Astra.IDE от 16.10.2026 (факты F01–F93, риски R1–R23, чек-лист A1–J3; продолжение чек-листа — раздел 9 migration_checklist.md).
Факты пересказаны кратко, первоисточники — в разделе [«Ссылки»](#ссылки); полная таблица фактов —
в [приложении к таблице различий](differences.md#приложение-факты-и-источники).

Счёт ведётся по разобранному тексту: комментарии и строки не учитываются. В ячейках с количеством —
`src / tests`; «—» — у источника таких мест нет. Единицы: объект, член (метод или свойство), секция
`VAR…END_VAR`, переменная, вхождение (место в тексте).

## Источники

| Источник | Путь | Ревизия | Каталоги | Объектов | Примечание |
|---|---|---|---|---|---|
| Библиотека plc-process-lib | `../plc-process-lib` | `integrate` = `4b0541c` (2026-10-19) | src, tests | 115 | — |
| Флагман kns-pump-station | `../kns-pump-station` | `HEAD` = `17338f9` (2026-10-16) | src, tests | 0 | 11 объектов совпадают с базовой линией «пример шаблона plc-repo-template» и пропущены; **собственных исходников пока нет**; задачи config.json только с объектами базовой линии пропущены: `normal/MainTask`, `test/TestTask` |

## Объём кода

| Источник | Каталог | DUT | GVL | PVL | интерфейсы | FUNCTION | FUNCTION_BLOCK | PROGRAM | Методы | Свойства | Файлов | Строк | Строк кода |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Библиотека plc-process-lib | `src` | 50 | 2 | 0 | 7 | 5 | 14 | 1 | 76 | 38 | 318 | 5490 | 4199 |
| Библиотека plc-process-lib | `tests` | 7 | 7 | 0 | 0 | 0 | 21 | 1 | 440 | 2 | 942 | 16260 | 13876 |
| Флагман kns-pump-station | — | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

## Шкала риска

- **высокий** — у вендора не подтверждено, а при отказе нужна переделка структуры кода; или известное ограничение REGUL, которое требует правки кода.
- **средний** — у вендора не описано, но есть в базе CODESYS 3.5.17; проверить пробной компиляцией (пункт чек-листа), при отказе правка локальная.
- **низкий** — подтверждено документацией вендора; правки не ожидаются.
- **нет** — базовый МЭК 61131-3 или к Astra.IDE не относится.

## Главные риски

Возможности со средним и высоким риском, которые используются в коде, — по убыванию риска и числа мест.

| Риск | Возможность | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Ссылки | Что делать |
|---|---|---|---|---|---|
| высокий | coUnit (юнит-тесты: `coUnit.*`, методы `Assert*`) | 0 / 3622 | — | [F73](#ref-f73), [R18](#ref-r18), [H2](#ref-h2), [H3](#ref-h3) | Сначала собрать тестовый проект с coUnit (H2); при отказе тесты логики — в CODESYS 3.5.17.30, на REGUL — интеграционные сценарии и PsUnittest |
| высокий | Наследование ФБ (`FUNCTION_BLOCK … EXTENDS`) | 7 / 18 | — | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Первым делом — пробный импорт иерархии; при отказе — композиция и интерфейсы, правки `// PORT:` |
| высокий | Вызов базовой реализации (`SUPER^`) | 6 / 3 | — | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Вместе с `EXTENDS`; при композиции — явный вызов вложенного экземпляра |
| средний | Спецификатор `PRIVATE` | 0 / 428 | — | [F23](#ref-f23), [C3](#ref-c3) | Проверить компиляцией; при отказе — убрать спецификатор (доступ станет `PUBLIC`, поведение то же) |
| средний | Литералы `LTIME#`, `LT#` | 13 / 86 | — | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) |
| средний | Переменные интерфейсного типа | 8 / 71 | — | [F85](#ref-f85), [R8](#ref-r8), [G4](#ref-g4) | В коде — как есть; в символьную конфигурацию OPC UA не публиковать (проверить G4) |
| средний | Тип `LTIME` | 37 / 19 | — | [F30](#ref-f30), [F34](#ref-f34), [C11](#ref-c11) | Тип есть (структура OPC UA `ua_var_ltime`); арифметику проверить (C11); в OPC UA — как `ULINT` нс |
| средний | Спецификатор `PROTECTED` | 49 / 5 | — | [F23](#ref-f23), [C3](#ref-c3) | Как `PRIVATE`; зависит от `EXTENDS` |
| средний | Аксессор `Get` | 38 / 2 | — | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойством |
| средний | Перечисления с базовым типом (`(…) INT`) | 24 / 0 | — | [F34](#ref-f34), [R17](#ref-r17), [C7](#ref-c7) | Проверить (C7); при отказе — без базового типа, с явными значениями |
| средний | `VAR_IN_OUT CONSTANT` | 16 / 7 | — | [C13](#ref-c13) | Проверить (C13); при отказе — `VAR_IN_OUT` без `CONSTANT` |
| средний | Свойства ФБ (`PROPERTY`) | 19 / 2 | — | [F22](#ref-f22), [C3](#ref-c3) | У вендора свойства показаны только у библиотечных ФБ; проверить в пользовательском ФБ (C3), при отказе — методы `GetX`/`SetX` |
| средний | Свойства интерфейсов | 19 / 0 | — | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойствами ФБ |
| средний | Преобразования `*_TO_LTIME`, `LTIME_TO_*` | 19 / 0 | — | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) |
| средний | `{attribute 'strict'}` | 18 / 0 | — | [F29](#ref-f29), [R16](#ref-r16), [C5](#ref-c5) | Проверить, что неквалифицированное обращение даёт ошибку; иначе следить вручную |
| средний | `{attribute 'linkalways'}` | 0 / 7 | — | [C14](#ref-c14) | В документации РегЛаб нет; проверить, что GVL без ссылок из кода попадает в приложение (C14) |
| средний | `THIS^` | 4 / 1 | — | [F23](#ref-f23), [C2](#ref-c2) | Проверить компиляцией; при отказе — обращение без `THIS^` |
| средний | Наследование интерфейсов (`INTERFACE … EXTENDS`) | 3 / 0 | — | [F23](#ref-f23), [C4](#ref-c4) | Проверить пробной компиляцией; при отказе — плоские интерфейсы с повтором методов |
| средний | Задачи из `tools/codesys/config.json` | 2 | — | [F04](#ref-f04), [R13](#ref-r13), [J1](#ref-j1) | Переназначить приоритеты: на REGUL пользовательские 2–15 (ЦП I/III) или 5–15 (ЦП II) |
| средний | Оператор `LTIME()` (монотонное время) | 1 / 0 | — | [F52](#ref-f52), [R20](#ref-r20), [C11](#ref-c11) | Проверить на REGUL; запасной путь — `FB_TimeSource_Regul` на `PsTimeGetUtcTimeNs` или `SysTimeRtc` |
| средний | `ABSTRACT` (ФБ, метод, свойство) | 1 / 0 | — | [F23](#ref-f23), [R15](#ref-r15), [C2](#ref-c2) | При отказе — интерфейс вместо абстрактного ФБ |

## ООП

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| Интерфейсы (`INTERFACE`) | объект | 7 / 0 | — | низкий | [F19](#ref-f19), [F20](#ref-f20), [B3](#ref-b3) | Переносить как есть; импорт интерфейсов через PLCopenXML проверить (B3) | `I_Alarm`, `I_AlarmSink`, `I_AlarmSource`, `I_Device`, `I_Motor`, `I_MotorVfd`, `I_TimeSource` |  |
| Наследование интерфейсов (`INTERFACE … EXTENDS`) | объект | 3 / 0 | — | средний | [F23](#ref-f23), [C4](#ref-c4) | Проверить пробной компиляцией; при отказе — плоские интерфейсы с повтором методов | `I_Device`, `I_Motor`, `I_MotorVfd` | `I_AlarmSource`, `I_Device`, `I_Motor` |
| Реализация интерфейсов (`IMPLEMENTS`) | POU | 6 / 1 | — | низкий | [F20](#ref-f20), [F21](#ref-f21) | Переносить как есть | `FB_Alarm`, `FB_DeviceBase`, `FB_FakeTime`, `FB_Motor`, `FB_MotorVfd`, `FB_SystemTime`, `FB_TestSink` | `I_TimeSource` ×2, `I_Alarm`, `I_AlarmSink`, `I_Device`, `I_Motor`, `I_MotorVfd` |
| Наследование ФБ (`FUNCTION_BLOCK … EXTENDS`) | ФБ | 7 / 18 | — | высокий | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Первым делом — пробный импорт иерархии; при отказе — композиция и интерфейсы, правки `// PORT:` | `FB_Alarm_Test`, `FB_AnalogInput`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve`, `FB_ControlValve_Test`, `FB_DeviceBase_Test`, `FB_DigitalInput` и ещё 17 | `coUnit.FB_TestSuite` ×14, `FB_DeviceBase` ×7, `FB_TestDevice` ×2, `FB_Motor`, `FB_ProbeHookBase` |
| Вызов базовой реализации (`SUPER^`) | вхожд. | 6 / 3 | — | высокий | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Вместе с `EXTENDS`; при композиции — явный вызов вложенного экземпляра | `FB_ControlValve`, `FB_Motor`, `FB_MotorVfd`, `FB_PID`, `FB_TestDevice`, `FB_TestDeviceExt`, `FB_Valve` | `SUPER^.метод` ×7, `SUPER^(…) — тело базы` ×2 |
| `THIS^` | вхожд. | 4 / 1 | — | средний | [F23](#ref-f23), [C2](#ref-c2) | Проверить компиляцией; при отказе — обращение без `THIS^` | `FB_DeviceBase`, `FB_Motor`, `FB_MotorVfd`, `FB_ProbeHookBase` |  |
| `ABSTRACT` (ФБ, метод, свойство) | член | 1 / 0 | — | средний | [F23](#ref-f23), [R15](#ref-r15), [C2](#ref-c2) | При отказе — интерфейс вместо абстрактного ФБ | `FB_DeviceBase` | `POU` |
| Методы ФБ и программ (`METHOD`) | метод | 67 / 440 | — | низкий | [F19](#ref-f19), [F21](#ref-f21), [F22](#ref-f22) | Переносить как есть | `FB_Alarm`, `FB_Alarm_Test`, `FB_AnalogInput`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve`, `FB_ControlValve_Test`, `FB_Delay` и ещё 25 |  |
| Методы интерфейсов | метод | 9 / 0 | — | низкий | [F20](#ref-f20) | Переносить как есть | `I_Alarm`, `I_AlarmSink`, `I_AlarmSource`, `I_Device`, `I_TimeSource` |  |
| Спецификатор `PUBLIC` | член | 37 / 9 | — | низкий | [F21](#ref-f21) | Переносить как есть | `FB_Alarm`, `FB_Delay`, `FB_DeviceBase`, `FB_FakeTime`, `FB_FopdtModel`, `FB_Motor`, `FB_MotorVfd`, `FB_ProbeHookBase` и ещё 4 | `метод` ×25, `свойство` ×21 |
| Спецификатор `PRIVATE` | член | 0 / 428 | — | средний | [F23](#ref-f23), [C3](#ref-c3) | Проверить компиляцией; при отказе — убрать спецификатор (доступ станет `PUBLIC`, поведение то же) | `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve_Test`, `FB_DeviceBase_Test`, `FB_DigitalInput_Test`, `FB_Integration_Test`, `FB_Motor_Test` и ещё 6 | `метод` ×428 |
| Спецификатор `PROTECTED` | член | 49 / 5 | — | средний | [F23](#ref-f23), [C3](#ref-c3) | Как `PRIVATE`; зависит от `EXTENDS` | `FB_Alarm`, `FB_AnalogInput`, `FB_ControlValve`, `FB_DeviceBase`, `FB_DigitalInput`, `FB_Motor`, `FB_MotorVfd`, `FB_PID` и ещё 5 | `метод` ×54 |
| Свойства ФБ (`PROPERTY`) | свойство | 19 / 2 | — | средний | [F22](#ref-f22), [C3](#ref-c3) | У вендора свойства показаны только у библиотечных ФБ; проверить в пользовательском ФБ (C3), при отказе — методы `GetX`/`SetX` | `FB_Alarm`, `FB_DeviceBase`, `FB_Motor`, `FB_MotorVfd`, `FB_TestSink` |  |
| Аксессор `Get` | аксессор | 38 / 2 | — | средний | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойством | `FB_Alarm`, `FB_DeviceBase`, `FB_Motor`, `FB_MotorVfd`, `FB_TestSink`, `I_Alarm`, `I_AlarmSource`, `I_Device` и ещё 2 |  |
| Свойства интерфейсов | свойство | 19 / 0 | — | средний | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойствами ФБ | `I_Alarm`, `I_AlarmSource`, `I_Device`, `I_Motor`, `I_MotorVfd` |  |
| Переменные интерфейсного типа | перем. | 8 / 71 | — | средний | [F85](#ref-f85), [R8](#ref-r8), [G4](#ref-g4) | В коде — как есть; в символьную конфигурацию OPC UA не публиковать (проверить G4) | `FB_Alarm`, `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve_Test`, `FB_Delay`, `FB_DeviceBase`, `FB_DeviceBase_Test` и ещё 10 | `I_Alarm` ×53, `I_TimeSource` ×12, `I_Device` ×6, `I_Motor` ×3, `I_AlarmSink` ×2, `I_MotorVfd` ×2 и ещё 1 |

Не используются: `FINAL`; Метод или свойство без спецификатора (по умолчанию `PUBLIC`); Спецификатор `INTERNAL`; Аксессор `Set`; Конструктор `FB_init`; `FB_exit`, `FB_reinit`; `__QUERYINTERFACE`, `__QUERYPOINTER`.

## Прагмы и атрибуты

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| `{attribute 'linkalways'}` | вхожд. | 0 / 7 | — | средний | [C14](#ref-c14) | В документации РегЛаб нет; проверить, что GVL без ссылок из кода попадает в приложение (C14) | `GVL_TestsAiDi`, `GVL_TestsAlarm`, `GVL_TestsFoundation`, `GVL_TestsIntegration`, `GVL_TestsMotor`, `GVL_TestsPid`, `GVL_TestsValve` |  |
| `{attribute 'qualified_only'}` | вхожд. | 52 / 14 | — | низкий | [F25](#ref-f25) | Есть | `E_AiAlarm`, `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult` и ещё 58 |  |
| `{attribute 'strict'}` | вхожд. | 18 / 0 | — | средний | [F29](#ref-f29), [R16](#ref-r16), [C5](#ref-c5) | Проверить, что неквалифицированное обращение даёт ошибку; иначе следить вручную | `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult`, `E_CvFaultAction` и ещё 10 |  |

Не используются: Условная компиляция `{IF …}`; Прагмы сообщений `{warning}`, `{error}`, `{info}`; Прочие прагмы.

## Библиотеки и пространства имён

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| coUnit (юнит-тесты: `coUnit.*`, методы `Assert*`) | вхожд. | 0 / 3622 | — | высокий | [F73](#ref-f73), [R18](#ref-r18), [H2](#ref-h2), [H3](#ref-h3) | Сначала собрать тестовый проект с coUnit (H2); при отказе тесты логики — в CODESYS 3.5.17.30, на REGUL — интеграционные сценарии и PsUnittest | `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve_Test`, `FB_DeviceBase_Test`, `FB_DigitalInput_Test`, `FB_Integration_Test`, `FB_Motor_Test` и ещё 7 | `AssertTrue` ×1192, `AssertEquals_WORD` ×429, `coUnit.TEST` ×420, `coUnit.TEST_FINISHED` ×420, `AssertEquals_REAL` ×418, `AssertFalse` ×353 и ещё 8 |

Не используются: Standard (таймеры, триггеры, счётчики, строки); Standard64 (`LTON`/`LTOF`/`LTP`, `LCTU`…, функции `WSTRING`); Util; SysTime, SysTimeCore, SysTimeRtc; SysFile, SysDir; CAA File (`FILE.*`); CAA Memory (`MEM`), CAA SerialCom (`COM`); Библиотеки устройства (`IoStandard`, CAA Device Diagnosis `DED`); Компоненты рантайма (CmpLog, CmpApp, CmpIecTask, SysMem, SysCom, SysSocket); IECStringUtils, Base Interfaces, Breakpoint Logging; Своя библиотека `PL` (plc-process-lib).

## Типы данных

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| Тип `LTIME` | вхожд. | 37 / 19 | — | средний | [F30](#ref-f30), [F34](#ref-f34), [C11](#ref-c11) | Тип есть (структура OPC UA `ua_var_ltime`); арифметику проверить (C11); в OPC UA — как `ULINT` нс | `F_LTimeToSec`, `FB_Alarm`, `FB_Alarm_Test`, `FB_Delay`, `FB_DeviceBase`, `FB_FakeTime`, `FB_Motor`, `FB_PID` и ещё 11 |  |
| Литералы `LTIME#`, `LT#` | вхожд. | 13 / 86 | — | средний | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) | `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_DeviceBase`, `FB_DeviceBase_Test`, `FB_FakeTime`, `FB_Motor`, `FB_Motor_Test` и ещё 8 |  |
| Преобразования `*_TO_LTIME`, `LTIME_TO_*` | вхожд. | 19 / 0 | — | средний | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) | `F_LTimeToSec`, `FB_Alarm`, `FB_Delay`, `FB_FakeTime`, `FB_Motor`, `FB_PID` | `TIME_TO_LTIME` ×11, `LTIME_TO_ULINT` ×5, `LTIME_TO_TIME` ×2, `ULINT_TO_LTIME` |
| `LINT`, `ULINT`, `LWORD` | вхожд. | 2 / 0 | — | низкий | [F30](#ref-f30) | Переносить как есть | `FB_Motor` | `ULINT` ×2 |
| Структуры (`STRUCT`) | DUT | 25 / 3 | — | низкий | [F32](#ref-f32) | Переносить как есть | `ST_AiLimitCfg`, `ST_AlarmCfg`, `ST_AlarmEvent`, `ST_AnalogInputCfg`, `ST_AnalogInputCmd`, `ST_AnalogInputSts`, `ST_ControlValveCfg`, `ST_ControlValveCmd` и ещё 20 |  |
| Объединения (`UNION`) | DUT | 1 / 4 | — | низкий | [F32](#ref-f32), [C8](#ref-c8) | Есть; `UNION` в составе структуры проверить (C8) | `U_AiDiTestEnum`, `U_RealBits`, `U_TestEnumInt`, `U_TestPidEnumInt`, `U_TestValveEnum` |  |
| Перечисления | DUT | 24 / 0 | — | низкий | [F33](#ref-f33) | Переносить как есть | `E_AiAlarm`, `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult` и ещё 16 |  |
| Перечисления с базовым типом (`(…) INT`) | DUT | 24 / 0 | — | средний | [F34](#ref-f34), [R17](#ref-r17), [C7](#ref-c7) | Проверить (C7); при отказе — без базового типа, с явными значениями | `E_AiAlarm`, `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult` и ещё 16 | `INT` ×18, `UINT` ×6 |

Не используются: `WSTRING` и литералы `"…"`; `LDATE`, `LTOD`, `LDT`; `REFERENCE TO`; `POINTER TO`; Наследование структур (`STRUCT … EXTENDS`); Псевдонимы типов; Поддиапазоны (`INT(0..100)`); Массивы переменной длины `ARRAY[*]`; Обобщённые типы `ANY`, `ANY_*`; Тип `BIT`; `__XINT`, `__UXINT`, `__XWORD`.

## Конструкции языка

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| `VAR_IN_OUT` | секция | 13 / 9 | — | низкий | [C13](#ref-c13) | Базовый МЭК; с массивами и строками проверить (C13) | `FB_AnalogInput`, `FB_AnalogInput_Test`, `FB_ControlValve`, `FB_DeviceBase`, `FB_DeviceBase_Test`, `FB_DigitalInput`, `FB_DigitalInput_Test`, `FB_Motor` и ещё 6 |  |
| `VAR_IN_OUT CONSTANT` | секция | 16 / 7 | — | средний | [C13](#ref-c13) | Проверить (C13); при отказе — `VAR_IN_OUT` без `CONSTANT` | `FB_AnalogInput`, `FB_ControlValve`, `FB_DeviceBase`, `FB_DigitalInput`, `FB_Motor`, `FB_Motor_Test`, `FB_MotorVfd`, `FB_MotorVfd_Test` и ещё 6 |  |
| `VAR_TEMP` | секция | 9 / 1 | — | нет | — | Базовый МЭК | `FB_Alarm`, `FB_AnalogInput`, `FB_ControlValve`, `FB_Delay`, `FB_DigitalInput`, `FB_LimitMonitor`, `FB_Motor`, `FB_PID` и ещё 2 |  |
| Локальные константы (`VAR CONSTANT`) | секция | 0 / 4 | — | нет | — | Базовый МЭК | `FB_FopdtModel`, `FB_Runtime_Test`, `FB_TestDevice`, `FB_TestSink` |  |
| `VAR_GLOBAL CONSTANT` | секция | 8 / 0 | — | низкий | [F47](#ref-f47) | Переносить как есть | `GVL_Const` |  |
| Оператор `LTIME()` (монотонное время) | вхожд. | 1 / 0 | — | средний | [F52](#ref-f52), [R20](#ref-r20), [C11](#ref-c11) | Проверить на REGUL; запасной путь — `FB_TimeSource_Regul` на `PsTimeGetUtcTimeNs` или `SysTimeRtc` | `FB_SystemTime` |  |
| `SIZEOF` | вхожд. | 0 / 31 | — | низкий | [§2.9](#ref-29) | Есть в примерах вендора (`ModbusUserRequest2`) | `FB_Common_Test`, `FB_DeviceBase_Test`, `FB_Util_Test` |  |

Не используются: `VAR_STAT`; `VAR_INST`; `VAR_EXTERNAL`; GVL с `VAR_GLOBAL` и `VAR_GLOBAL CONSTANT` в одном объекте; Оператор `TIME()`; `ADR`; `BITADR`; Разыменование `^`; Присваивание ссылки `REF=`; `__NEW`, `__DELETE`; `__ISVALIDREF`; `__TRY` … `__ENDTRY`; `__SYSTEM.*`; Прочие операторы `__*`; POU неявных проверок (`CheckBounds`, `CheckDivInt`…).

## RETAIN и PERSISTENT

В коде не найдено.

Не используются: `RETAIN`; `PERSISTENT`; Объект Persistent Variables (`*.pvl.st`); `NON_RETAIN`.

## Привязка к вводу-выводу

В коде не найдено.

Не используются: `AT %I*` / `%Q*` (адрес назначается в дереве устройств); `AT` с фиксированным адресом (`%IX0.0`, `%QW2`); `AT %M…`; Прямые адреса в коде.

## Задачи

Риск: средний ([F04](#ref-f04), [R13](#ref-r13), [J1](#ref-j1)). Переназначить приоритеты: на REGUL пользовательские 2–15 (ЦП I/III) или 5–15 (ЦП II).

| Источник | Режим | Задача | Интервал, мс | Приоритет | POU | Замечание для REGUL |
|---|---|---|---|---|---|---|
| Библиотека plc-process-lib | `normal` | `MainTask` | 20 | — | `PRG_Main` | приоритет в config.json не задан (CODESYS ставит своё значение по умолчанию); на REGUL задать явно: 2–15 на ЦП I/III типа, 5–15 на ЦП II типа |
| Библиотека plc-process-lib | `test` | `TestTask` | 10 | — | `PRG_Tests` | приоритет в config.json не задан (CODESYS ставит своё значение по умолчанию); на REGUL задать явно: 2–15 на ЦП I/III типа, 5–15 на ЦП II типа |

Ссылки на библиотеки в `tools/codesys/config.json`:

| Источник | Ключ | Библиотека | Версия | Пространство имён | Режимы | Риск | Ссылки |
|---|---|---|---|---|---|---|---|
| Библиотека plc-process-lib | `counit` | coUnit (CfUnit) 1.2.0.0 | 1.2.0.0 | `coUnit` | `test` | высокий | [F73](#ref-f73), [R18](#ref-r18), [H2](#ref-h2), [H3](#ref-h3) |
| Библиотека plc-process-lib | `standard` | Standard (плейсхолдер #Standard, версию задаёт профиль CODESYS) | * | `Standard` | `normal`, `test` | низкий | [F50](#ref-f50) |

## Идентификаторы

Имена, которые CODESYS допускает, а другие инструменты МЭК считают ключевыми словами. Для Astra.IDE
(база CODESYS 3.5.17, [F01](#ref-f01)) они не мешают; важны для RuSTy и iec_checker в CI и для
следующих сред (MasterSCADA 4D, «Полигон» — их списки ключевых слов здесь не проверялись).

Объявленных имён, зарезервированных в RuSTy 1.0.6 и iec_checker 0.4, нет.

Имена объектов с префиксом `Ps` (занят библиотеками РегЛаб, [F54](#ref-f54), [F79](#ref-f79)): нет.

Списки ключевых слов:

- RuSTy 1.0.6: [RuSTy 1.0.6, лексер compiler/plc_lexer/src/lexer/tokens.rs](https://github.com/PLC-lang/rusty/blob/v1.0.6/compiler/plc_lexer/src/lexer/tokens.rs)
- iec_checker 0.4: [iec_checker 0.4, лексер src/parser/lexer.mll (таблица ключевых слов и управляющие слова)](https://github.com/iec-checker/iec-checker/blob/v0.4/src/parser/lexer.mll)

## Не покрыто исследованием

Найдены в коде, но фактов о них в исследовании Astra.IDE нет — проверяются по чек-листу «проверить вручную».

| Возможность | Риск | Вхождений | Чек-лист | Что сделать |
|---|---|---|---|---|
| `{attribute 'linkalways'}` | средний | 7 | [C14](#ref-c14) | В документации РегЛаб нет; проверить, что GVL без ссылок из кода попадает в приложение (C14) |
| `VAR_IN_OUT` | низкий | 22 | [C13](#ref-c13) | Базовый МЭК; с массивами и строками проверить (C13) |
| `VAR_IN_OUT CONSTANT` | средний | 23 | [C13](#ref-c13) | Проверить (C13); при отказе — `VAR_IN_OUT` без `CONSTANT` |

## Где именно

Файлы и строки по каждой возможности (не больше 25 файлов; остальное — в `docs/inventory.json`).

<details><summary>Интерфейсы (<code>INTERFACE</code>) — 7</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Alarm/I_Alarm.itf.st` (I_Alarm): 6
- `src/Interfaces/I_AlarmSink/I_AlarmSink.itf.st` (I_AlarmSink): 6
- `src/Interfaces/I_AlarmSource/I_AlarmSource.itf.st` (I_AlarmSource): 6
- `src/Interfaces/I_Device/I_Device.itf.st` (I_Device): 7
- `src/Interfaces/I_Motor/I_Motor.itf.st` (I_Motor): 6
- `src/Interfaces/I_MotorVfd/I_MotorVfd.itf.st` (I_MotorVfd): 6
- `src/Interfaces/I_TimeSource/I_TimeSource.itf.st` (I_TimeSource): 6

</details>

<details><summary>Наследование интерфейсов (<code>INTERFACE … EXTENDS</code>) — 3</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Device/I_Device.itf.st` (I_Device): 7
- `src/Interfaces/I_Motor/I_Motor.itf.st` (I_Motor): 6
- `src/Interfaces/I_MotorVfd/I_MotorVfd.itf.st` (I_MotorVfd): 6

</details>

<details><summary>Реализация интерфейсов (<code>IMPLEMENTS</code>) — 7</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/FB_Alarm.decl.st` (FB_Alarm): 11
- `src/POUs/Base/FB_DeviceBase/FB_DeviceBase.decl.st` (FB_DeviceBase): 11
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 13
- `src/POUs/Devices/FB_MotorVfd/FB_MotorVfd.decl.st` (FB_MotorVfd): 10
- `src/POUs/Time/FB_FakeTime/FB_FakeTime.decl.st` (FB_FakeTime): 9
- `src/POUs/Time/FB_SystemTime/FB_SystemTime.decl.st` (FB_SystemTime): 9
- `tests/POUs/Helpers/FB_TestSink/FB_TestSink.decl.st` (FB_TestSink): 7

</details>

<details><summary>Наследование ФБ (<code>FUNCTION_BLOCK … EXTENDS</code>) — 25</summary>

Библиотека plc-process-lib:

- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 12
- `src/POUs/Devices/FB_AnalogInput/FB_AnalogInput.decl.st` (FB_AnalogInput): 12
- `src/POUs/Devices/FB_ControlValve/FB_ControlValve.decl.st` (FB_ControlValve): 11
- `src/POUs/Devices/FB_DigitalInput/FB_DigitalInput.decl.st` (FB_DigitalInput): 9
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 13
- `src/POUs/Devices/FB_MotorVfd/FB_MotorVfd.decl.st` (FB_MotorVfd): 10
- `src/POUs/Devices/FB_Valve/FB_Valve.decl.st` (FB_Valve): 13
- `tests/POUs/Helpers/FB_ProbeHookDerived/FB_ProbeHookDerived.decl.st` (FB_ProbeHookDerived): 6
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 12
- `tests/POUs/Helpers/FB_TestDeviceExt/FB_TestDeviceExt.decl.st` (FB_TestDeviceExt): 8
- `tests/POUs/Helpers/FB_TestDeviceNoSuper/FB_TestDeviceNoSuper.decl.st` (FB_TestDeviceNoSuper): 7
- `tests/POUs/Suites/FB_Alarm_Test/FB_Alarm_Test.decl.st` (FB_Alarm_Test): 8
- `tests/POUs/Suites/FB_AnalogInput_Test/FB_AnalogInput_Test.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_Common_Test/FB_Common_Test.decl.st` (FB_Common_Test): 9
- `tests/POUs/Suites/FB_ControlValve_Test/FB_ControlValve_Test.decl.st` (FB_ControlValve_Test): 10
- `tests/POUs/Suites/FB_DeviceBase_Test/FB_DeviceBase_Test.decl.st` (FB_DeviceBase_Test): 10
- `tests/POUs/Suites/FB_DigitalInput_Test/FB_DigitalInput_Test.decl.st` (FB_DigitalInput_Test): 8
- `tests/POUs/Suites/FB_Integration_Test/FB_Integration_Test.decl.st` (FB_Integration_Test): 8
- `tests/POUs/Suites/FB_MotorVfd_Test/FB_MotorVfd_Test.decl.st` (FB_MotorVfd_Test): 8
- `tests/POUs/Suites/FB_Motor_Test/FB_Motor_Test.decl.st` (FB_Motor_Test): 9
- `tests/POUs/Suites/FB_Pid_Test/FB_Pid_Test.decl.st` (FB_Pid_Test): 11
- `tests/POUs/Suites/FB_Runtime_Test/FB_Runtime_Test.decl.st` (FB_Runtime_Test): 11
- `tests/POUs/Suites/FB_Time_Test/FB_Time_Test.decl.st` (FB_Time_Test): 7
- `tests/POUs/Suites/FB_Util_Test/FB_Util_Test.decl.st` (FB_Util_Test): 7
- `tests/POUs/Suites/FB_Valve_Test/FB_Valve_Test.decl.st` (FB_Valve_Test): 11

</details>

<details><summary>Вызов базовой реализации (<code>SUPER^</code>) — 9</summary>

Библиотека plc-process-lib:

- `src/POUs/Control/FB_PID/OnModeChanged.method.impl.st` (FB_PID): 1
- `src/POUs/Devices/FB_ControlValve/OnModeChanged.method.impl.st` (FB_ControlValve): 1
- `src/POUs/Devices/FB_Motor/OnModeChanged.method.impl.st` (FB_Motor): 1
- `src/POUs/Devices/FB_MotorVfd/CheckConfig.method.impl.st` (FB_MotorVfd): 1
- `src/POUs/Devices/FB_MotorVfd/FB_MotorVfd.impl.st` (FB_MotorVfd): 54
- `src/POUs/Devices/FB_Valve/OnModeChanged.method.impl.st` (FB_Valve): 1
- `tests/POUs/Helpers/FB_TestDevice/OnModeChanged.method.impl.st` (FB_TestDevice): 1
- `tests/POUs/Helpers/FB_TestDeviceExt/FB_TestDeviceExt.impl.st` (FB_TestDeviceExt): 5
- `tests/POUs/Helpers/FB_TestDeviceExt/OnModeChanged.method.impl.st` (FB_TestDeviceExt): 1

</details>

<details><summary><code>THIS^</code> — 5</summary>

Библиотека plc-process-lib:

- `src/POUs/Base/FB_DeviceBase/ProcessMode.method.impl.st` (FB_DeviceBase): 52
- `src/POUs/Base/FB_DeviceBase/SwitchRemoteMode.method.impl.st` (FB_DeviceBase): 6
- `src/POUs/Devices/FB_Motor/FB_Motor.impl.st` (FB_Motor): 20
- `src/POUs/Devices/FB_MotorVfd/FB_MotorVfd.impl.st` (FB_MotorVfd): 12
- `tests/POUs/Helpers/FB_ProbeHookBase/CallViaThis.method.impl.st` (FB_ProbeHookBase): 1

</details>

<details><summary><code>ABSTRACT</code> (ФБ, метод, свойство) — 1</summary>

Библиотека plc-process-lib:

- `src/POUs/Base/FB_DeviceBase/FB_DeviceBase.decl.st` (FB_DeviceBase): 11

</details>

<details><summary>Методы ФБ и программ (<code>METHOD</code>) — 507</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/Ack.method.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/ReleaseState.method.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/Shelve.method.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/Transit.method.decl.st` (FB_Alarm): 4
- `src/POUs/Alarm/FB_Alarm/Unshelve.method.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/UpdateShelve.method.decl.st` (FB_Alarm): 4
- `src/POUs/Alarm/FB_Alarm/UpdateState.method.decl.st` (FB_Alarm): 4
- `src/POUs/Base/FB_DeviceBase/AcceptCfg.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/AckAll.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/BeginCycle.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/CheckAlarmCfg.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/FinishCycle.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Base/FB_DeviceBase/GetAlarm.method.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/OnModeChanged.method.decl.st` (FB_DeviceBase): 6
- `src/POUs/Base/FB_DeviceBase/ProcessMode.method.decl.st` (FB_DeviceBase): 5
- `src/POUs/Base/FB_DeviceBase/RequestMode.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Base/FB_DeviceBase/Reset.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/ResolveTime.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Base/FB_DeviceBase/RunAlarms.method.decl.st` (FB_DeviceBase): 5
- `src/POUs/Base/FB_DeviceBase/SetCmdResult.method.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/SwitchRemoteMode.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Control/FB_PID/CalcStep.method.decl.st` (FB_PID): 6
- `src/POUs/Control/FB_PID/CheckConfig.method.decl.st` (FB_PID): 3
- `src/POUs/Control/FB_PID/OnModeChanged.method.decl.st` (FB_PID): 5
- `src/POUs/Control/FB_PID/RateStep.method.decl.st` (FB_PID): 5

… и ещё 482 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Методы интерфейсов — 9</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Alarm/Ack.method.decl.st` (I_Alarm): 2
- `src/Interfaces/I_Alarm/Shelve.method.decl.st` (I_Alarm): 2
- `src/Interfaces/I_Alarm/Unshelve.method.decl.st` (I_Alarm): 2
- `src/Interfaces/I_AlarmSink/OnAlarmEvent.method.decl.st` (I_AlarmSink): 2
- `src/Interfaces/I_AlarmSource/AckAll.method.decl.st` (I_AlarmSource): 2
- `src/Interfaces/I_AlarmSource/GetAlarm.method.decl.st` (I_AlarmSource): 2
- `src/Interfaces/I_Device/RequestMode.method.decl.st` (I_Device): 3
- `src/Interfaces/I_Device/Reset.method.decl.st` (I_Device): 2
- `src/Interfaces/I_TimeSource/Now.method.decl.st` (I_TimeSource): 2

</details>

<details><summary>Спецификатор <code>PUBLIC</code> — 46</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/Ack.method.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Active.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/AlarmPriority.prop.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/Id.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Seq.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Shelve.method.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/State.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Unacked.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Unshelve.method.decl.st` (FB_Alarm): 2
- `src/POUs/Base/FB_DeviceBase/AckAll.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/AlarmCount.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Available.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Fault.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/GetAlarm.method.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Mode.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/RequestMode.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Base/FB_DeviceBase/Reset.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/Status.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Devices/FB_Motor/CurrentRunSeconds.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/PresetCounters.method.decl.st` (FB_Motor): 4
- `src/POUs/Devices/FB_Motor/ReadyToStart.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/RunSeconds.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/Running.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/Starts.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_MotorVfd/SpeedAct.prop.decl.st` (FB_MotorVfd): 2

… и ещё 21 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Спецификатор <code>PRIVATE</code> — 428</summary>

Библиотека plc-process-lib:

- `tests/POUs/Suites/FB_Alarm_Test/AckAfterReturnGoesNormal.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/AckAndClearSameCallTwoEventsInOrder.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/AckInNormalReturnsFalse.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/AckWhileActiveGoesActiveAck.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/AckWithoutEffectNotKeptForLater.method.decl.st` (FB_Alarm_Test): 5
- `tests/POUs/Suites/FB_Alarm_Test/ActivateGoesActiveUnack.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/ActiveAckReturnGoesNormal.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/ActiveWhileShelvedFollowsCondition.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/InterfacePropertiesMatchOutputs.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/NoTimeSourceFallsBackToSystemTime.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/OffDelayHoldsActive.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/OnDelayShortConditionNoAlarm.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/OosEntryClearsUnackReannunciatesOnExit.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/OosOffWithSuppressActiveGoesSuppressed.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/OutOfServiceOverridesShelve.method.decl.st` (FB_Alarm_Test): 5
- `tests/POUs/Suites/FB_Alarm_Test/PriorityChangeWhileActiveNoEvent.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/PriorityNoneCancelsShelve.method.decl.st` (FB_Alarm_Test): 4
- `tests/POUs/Suites/FB_Alarm_Test/PriorityNoneNeverActivates.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/PriorityNoneToMediumActiveConditionActivates.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/PriorityOutOfEnumTreatedAsMedium.method.decl.st` (FB_Alarm_Test): 3
- `tests/POUs/Suites/FB_Alarm_Test/PriorityReenabledOnDelayCountsFromEnabling.method.decl.st` (FB_Alarm_Test): 5
- `tests/POUs/Suites/FB_Alarm_Test/ReactivateFromRtnUnackGoesActiveUnack.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/ReshelveRestartsTimer.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/ReturnWithoutAckGoesRtnUnack.method.decl.st` (FB_Alarm_Test): 2
- `tests/POUs/Suites/FB_Alarm_Test/SeqIncrementsOnEachTransition.method.decl.st` (FB_Alarm_Test): 3

… и ещё 403 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Спецификатор <code>PROTECTED</code> — 54</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/ReleaseState.method.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/Transit.method.decl.st` (FB_Alarm): 4
- `src/POUs/Alarm/FB_Alarm/UpdateShelve.method.decl.st` (FB_Alarm): 4
- `src/POUs/Alarm/FB_Alarm/UpdateState.method.decl.st` (FB_Alarm): 4
- `src/POUs/Base/FB_DeviceBase/AcceptCfg.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/BeginCycle.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/CheckAlarmCfg.method.decl.st` (FB_DeviceBase): 3
- `src/POUs/Base/FB_DeviceBase/FinishCycle.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Base/FB_DeviceBase/OnModeChanged.method.decl.st` (FB_DeviceBase): 6
- `src/POUs/Base/FB_DeviceBase/ProcessMode.method.decl.st` (FB_DeviceBase): 5
- `src/POUs/Base/FB_DeviceBase/ResolveTime.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Base/FB_DeviceBase/RunAlarms.method.decl.st` (FB_DeviceBase): 5
- `src/POUs/Base/FB_DeviceBase/SetCmdResult.method.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/SwitchRemoteMode.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Control/FB_PID/CalcStep.method.decl.st` (FB_PID): 6
- `src/POUs/Control/FB_PID/CheckConfig.method.decl.st` (FB_PID): 3
- `src/POUs/Control/FB_PID/OnModeChanged.method.decl.st` (FB_PID): 5
- `src/POUs/Control/FB_PID/RateStep.method.decl.st` (FB_PID): 5
- `src/POUs/Control/FB_PID/SelectOutput.method.decl.st` (FB_PID): 6
- `src/POUs/Devices/FB_AnalogInput/CallLimit.method.decl.st` (FB_AnalogInput): 4
- `src/POUs/Devices/FB_AnalogInput/CheckConfig.method.decl.st` (FB_AnalogInput): 3
- `src/POUs/Devices/FB_AnalogInput/ClassifySignal.method.decl.st` (FB_AnalogInput): 5
- `src/POUs/Devices/FB_AnalogInput/ComputeValue.method.decl.st` (FB_AnalogInput): 8
- `src/POUs/Devices/FB_AnalogInput/FaultBits.method.decl.st` (FB_AnalogInput): 2
- `src/POUs/Devices/FB_AnalogInput/SelectValue.method.decl.st` (FB_AnalogInput): 7

… и ещё 29 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Свойства ФБ (<code>PROPERTY</code>) — 21</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/Active.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/AlarmPriority.prop.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/Id.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Seq.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/State.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Unacked.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Base/FB_DeviceBase/AlarmCount.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Available.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Fault.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Mode.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Status.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Devices/FB_Motor/CurrentRunSeconds.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/ReadyToStart.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/RunSeconds.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/Running.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_Motor/Starts.prop.decl.st` (FB_Motor): 2
- `src/POUs/Devices/FB_MotorVfd/SpeedAct.prop.decl.st` (FB_MotorVfd): 2
- `src/POUs/Devices/FB_MotorVfd/SpeedAutoActive.prop.decl.st` (FB_MotorVfd): 2
- `src/POUs/Devices/FB_MotorVfd/SpeedRef.prop.decl.st` (FB_MotorVfd): 2
- `tests/POUs/Helpers/FB_TestSink/Count.prop.decl.st` (FB_TestSink): 2
- `tests/POUs/Helpers/FB_TestSink/Last.prop.decl.st` (FB_TestSink): 2

</details>

<details><summary>Аксессор <code>Get</code> — 40</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Alarm/Active.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/AlarmPriority.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/Id.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/Seq.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/State.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/Unacked.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_AlarmSource/AlarmCount.get.decl.st` (I_AlarmSource): 1
- `src/Interfaces/I_Device/Available.get.decl.st` (I_Device): 1
- `src/Interfaces/I_Device/Fault.get.decl.st` (I_Device): 1
- `src/Interfaces/I_Device/Mode.get.decl.st` (I_Device): 1
- `src/Interfaces/I_Device/Status.get.decl.st` (I_Device): 1
- `src/Interfaces/I_Motor/CurrentRunSeconds.get.decl.st` (I_Motor): 1
- `src/Interfaces/I_Motor/ReadyToStart.get.decl.st` (I_Motor): 1
- `src/Interfaces/I_Motor/RunSeconds.get.decl.st` (I_Motor): 1
- `src/Interfaces/I_Motor/Running.get.decl.st` (I_Motor): 1
- `src/Interfaces/I_Motor/Starts.get.decl.st` (I_Motor): 1
- `src/Interfaces/I_MotorVfd/SpeedAct.get.decl.st` (I_MotorVfd): 1
- `src/Interfaces/I_MotorVfd/SpeedAutoActive.get.decl.st` (I_MotorVfd): 1
- `src/Interfaces/I_MotorVfd/SpeedRef.get.decl.st` (I_MotorVfd): 1
- `src/POUs/Alarm/FB_Alarm/Active.get.impl.st` (FB_Alarm): 1
- `src/POUs/Alarm/FB_Alarm/AlarmPriority.get.impl.st` (FB_Alarm): 1
- `src/POUs/Alarm/FB_Alarm/Id.get.impl.st` (FB_Alarm): 1
- `src/POUs/Alarm/FB_Alarm/Seq.get.impl.st` (FB_Alarm): 1
- `src/POUs/Alarm/FB_Alarm/State.get.impl.st` (FB_Alarm): 1
- `src/POUs/Alarm/FB_Alarm/Unacked.get.impl.st` (FB_Alarm): 1

… и ещё 15 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Свойства интерфейсов — 19</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Alarm/Active.prop.decl.st` (I_Alarm): 2
- `src/Interfaces/I_Alarm/AlarmPriority.prop.decl.st` (I_Alarm): 3
- `src/Interfaces/I_Alarm/Id.prop.decl.st` (I_Alarm): 2
- `src/Interfaces/I_Alarm/Seq.prop.decl.st` (I_Alarm): 2
- `src/Interfaces/I_Alarm/State.prop.decl.st` (I_Alarm): 2
- `src/Interfaces/I_Alarm/Unacked.prop.decl.st` (I_Alarm): 2
- `src/Interfaces/I_AlarmSource/AlarmCount.prop.decl.st` (I_AlarmSource): 2
- `src/Interfaces/I_Device/Available.prop.decl.st` (I_Device): 2
- `src/Interfaces/I_Device/Fault.prop.decl.st` (I_Device): 2
- `src/Interfaces/I_Device/Mode.prop.decl.st` (I_Device): 2
- `src/Interfaces/I_Device/Status.prop.decl.st` (I_Device): 2
- `src/Interfaces/I_Motor/CurrentRunSeconds.prop.decl.st` (I_Motor): 2
- `src/Interfaces/I_Motor/ReadyToStart.prop.decl.st` (I_Motor): 2
- `src/Interfaces/I_Motor/RunSeconds.prop.decl.st` (I_Motor): 2
- `src/Interfaces/I_Motor/Running.prop.decl.st` (I_Motor): 2
- `src/Interfaces/I_Motor/Starts.prop.decl.st` (I_Motor): 2
- `src/Interfaces/I_MotorVfd/SpeedAct.prop.decl.st` (I_MotorVfd): 2
- `src/Interfaces/I_MotorVfd/SpeedAutoActive.prop.decl.st` (I_MotorVfd): 2
- `src/Interfaces/I_MotorVfd/SpeedRef.prop.decl.st` (I_MotorVfd): 2

</details>

<details><summary>Переменные интерфейсного типа — 79</summary>

Библиотека plc-process-lib:

- `src/GVLs/GVL_Lib.gvl.st` (GVL_Lib): 10
- `src/POUs/Alarm/FB_Alarm/FB_Alarm.decl.st` (FB_Alarm): 19, 46
- `src/POUs/Base/FB_DeviceBase/FB_DeviceBase.decl.st` (FB_DeviceBase): 13, 18
- `src/POUs/Time/FB_Delay/FB_Delay.decl.st` (FB_Delay): 13
- `src/POUs/Util/FB_LimitMonitor/FB_LimitMonitor.decl.st` (FB_LimitMonitor): 14, 25
- `tests/POUs/Suites/FB_Alarm_Test/ActiveWhileShelvedFollowsCondition.method.decl.st` (FB_Alarm_Test): 8
- `tests/POUs/Suites/FB_Alarm_Test/InterfacePropertiesMatchOutputs.method.decl.st` (FB_Alarm_Test): 7
- `tests/POUs/Suites/FB_Alarm_Test/PriorityChangeWhileActiveNoEvent.method.decl.st` (FB_Alarm_Test): 7
- `tests/POUs/Suites/FB_Alarm_Test/PriorityOutOfEnumTreatedAsMedium.method.decl.st` (FB_Alarm_Test): 11
- `tests/POUs/Suites/FB_Alarm_Test/SeqIncrementsOnEachTransition.method.decl.st` (FB_Alarm_Test): 8
- `tests/POUs/Suites/FB_AnalogInput_Test/At3p7mAIsOutOfSpecification.method.decl.st` (FB_AnalogInput_Test): 10
- `tests/POUs/Suites/FB_AnalogInput_Test/DefaultCfgFirstCallAutoTypeAndSlots.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_AnalogInput_Test/FailureForcesLimitsFalseAndSuppressesLimitAlarms.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_AnalogInput_Test/LimitDisabledNeverSets.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_AnalogInput_Test/LimitHHysteresisClearsBelowSpMinusHyst.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_AnalogInput_Test/LimitsOnFailEvaluatesFailValue.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_AnalogInput_Test/OutOfServiceHoldsValueInvalid.method.decl.st` (FB_AnalogInput_Test): 10
- `tests/POUs/Suites/FB_AnalogInput_Test/ResetCmdAcceptedAndAcksAlarms.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_AnalogInput_Test/SubstitutionDuringFailureLimitsOnSubstValue.method.decl.st` (FB_AnalogInput_Test): 12
- `tests/POUs/Suites/FB_AnalogInput_Test/SuppressLimitAlarmsInputFlagsStillSet.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_AnalogInput_Test/WireBreakSetsFailureAfterDelay.method.decl.st` (FB_AnalogInput_Test): 10
- `tests/POUs/Suites/FB_AnalogInput_Test/WireBreakShorterThanDelayNoFailure.method.decl.st` (FB_AnalogInput_Test): 9
- `tests/POUs/Suites/FB_Common_Test/InterfaceRefsDefaultToNull.method.decl.st` (FB_Common_Test): 5, 6, 7, 8, 9, 10, 11
- `tests/POUs/Suites/FB_ControlValve_Test/DefaultCfgPassesCheck.method.decl.st` (FB_ControlValve_Test): 10
- `tests/POUs/Suites/FB_ControlValve_Test/DeviationWarningAfterDelay.method.decl.st` (FB_ControlValve_Test): 12

… и ещё 40 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>{attribute 'linkalways'}</code> — 7</summary>

Библиотека plc-process-lib:

- `tests/GVLs/GVL_TestsAiDi.gvl.st` (GVL_TestsAiDi): 9
- `tests/GVLs/GVL_TestsAlarm.gvl.st` (GVL_TestsAlarm): 8
- `tests/GVLs/GVL_TestsFoundation.gvl.st` (GVL_TestsFoundation): 10
- `tests/GVLs/GVL_TestsIntegration.gvl.st` (GVL_TestsIntegration): 8
- `tests/GVLs/GVL_TestsMotor.gvl.st` (GVL_TestsMotor): 8
- `tests/GVLs/GVL_TestsPid.gvl.st` (GVL_TestsPid): 8
- `tests/GVLs/GVL_TestsValve.gvl.st` (GVL_TestsValve): 10

</details>

<details><summary><code>{attribute 'qualified_only'}</code> — 66</summary>

Библиотека plc-process-lib:

- `src/DUTs/Alarm/E_AlarmEventReason.dut.st` (E_AlarmEventReason): 5
- `src/DUTs/Alarm/E_AlarmPriority.dut.st` (E_AlarmPriority): 6
- `src/DUTs/Alarm/E_AlarmState.dut.st` (E_AlarmState): 7
- `src/DUTs/Alarm/ST_AlarmCfg.dut.st` (ST_AlarmCfg): 6
- `src/DUTs/Alarm/ST_AlarmEvent.dut.st` (ST_AlarmEvent): 6
- `src/DUTs/AnalogInput/E_AiAlarm.dut.st` (E_AiAlarm): 6
- `src/DUTs/AnalogInput/E_AiFailValue.dut.st` (E_AiFailValue): 5
- `src/DUTs/AnalogInput/E_AiInputType.dut.st` (E_AiInputType): 5
- `src/DUTs/AnalogInput/E_AiSignalState.dut.st` (E_AiSignalState): 6
- `src/DUTs/AnalogInput/ST_AiLimitCfg.dut.st` (ST_AiLimitCfg): 6
- `src/DUTs/AnalogInput/ST_AnalogInputCfg.dut.st` (ST_AnalogInputCfg): 7
- `src/DUTs/AnalogInput/ST_AnalogInputCmd.dut.st` (ST_AnalogInputCmd): 5
- `src/DUTs/AnalogInput/ST_AnalogInputSts.dut.st` (ST_AnalogInputSts): 6
- `src/DUTs/Common/E_CmdResult.dut.st` (E_CmdResult): 6
- `src/DUTs/Common/E_DeviceMode.dut.st` (E_DeviceMode): 7
- `src/DUTs/Common/E_DeviceType.dut.st` (E_DeviceType): 6
- `src/DUTs/Common/E_Ne107Status.dut.st` (E_Ne107Status): 7
- `src/DUTs/Common/ST_DeviceCmd.dut.st` (ST_DeviceCmd): 6
- `src/DUTs/Common/ST_DeviceRetain.dut.st` (ST_DeviceRetain): 9
- `src/DUTs/Common/ST_DeviceSts.dut.st` (ST_DeviceSts): 7
- `src/DUTs/Common/U_RealBits.dut.st` (U_RealBits): 6
- `src/DUTs/ControlValve/E_CvAlarm.dut.st` (E_CvAlarm): 6
- `src/DUTs/ControlValve/E_CvFaultAction.dut.st` (E_CvFaultAction): 5
- `src/DUTs/ControlValve/ST_ControlValveCfg.dut.st` (ST_ControlValveCfg): 7
- `src/DUTs/ControlValve/ST_ControlValveCmd.dut.st` (ST_ControlValveCmd): 5

… и ещё 41 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>{attribute 'strict'}</code> — 18</summary>

Библиотека plc-process-lib:

- `src/DUTs/Alarm/E_AlarmEventReason.dut.st` (E_AlarmEventReason): 6
- `src/DUTs/Alarm/E_AlarmPriority.dut.st` (E_AlarmPriority): 7
- `src/DUTs/Alarm/E_AlarmState.dut.st` (E_AlarmState): 8
- `src/DUTs/AnalogInput/E_AiFailValue.dut.st` (E_AiFailValue): 6
- `src/DUTs/AnalogInput/E_AiInputType.dut.st` (E_AiInputType): 6
- `src/DUTs/AnalogInput/E_AiSignalState.dut.st` (E_AiSignalState): 7
- `src/DUTs/Common/E_CmdResult.dut.st` (E_CmdResult): 7
- `src/DUTs/Common/E_DeviceMode.dut.st` (E_DeviceMode): 8
- `src/DUTs/Common/E_DeviceType.dut.st` (E_DeviceType): 7
- `src/DUTs/Common/E_Ne107Status.dut.st` (E_Ne107Status): 8
- `src/DUTs/ControlValve/E_CvFaultAction.dut.st` (E_CvFaultAction): 6
- `src/DUTs/DigitalInput/E_DiFailValue.dut.st` (E_DiFailValue): 6
- `src/DUTs/Motor/E_MotorState.dut.st` (E_MotorState): 6
- `src/DUTs/Pid/E_PidAction.dut.st` (E_PidAction): 6
- `src/DUTs/Pid/E_PidPvFailAction.dut.st` (E_PidPvFailAction): 6
- `src/DUTs/Valve/E_ValveSafePos.dut.st` (E_ValveSafePos): 6
- `src/DUTs/Valve/E_ValveState.dut.st` (E_ValveState): 6
- `src/DUTs/Valve/E_ValveType.dut.st` (E_ValveType): 6

</details>

<details><summary>coUnit (юнит-тесты: <code>coUnit.*</code>, методы <code>Assert*</code>) — 3622</summary>

Библиотека plc-process-lib:

- `tests/POUs/PRG_Tests/PRG_Tests.impl.st` (PRG_Tests): 5
- `tests/POUs/Suites/FB_Alarm_Test/AckAfterReturnGoesNormal.method.impl.st` (FB_Alarm_Test): 1, 7, 8, 9, 10, 11, 13
- `tests/POUs/Suites/FB_Alarm_Test/AckAndClearSameCallTwoEventsInOrder.method.impl.st` (FB_Alarm_Test): 1, 8, 10, 11, 13, 14, 15, 16, 18
- `tests/POUs/Suites/FB_Alarm_Test/AckInNormalReturnsFalse.method.impl.st` (FB_Alarm_Test): 1, 6, 7, 13, 14, 15, 17
- `tests/POUs/Suites/FB_Alarm_Test/AckWhileActiveGoesActiveAck.method.impl.st` (FB_Alarm_Test): 1, 5, 6, 10, 11, 12, 13, 14, 16
- `tests/POUs/Suites/FB_Alarm_Test/AckWithoutEffectNotKeptForLater.method.impl.st` (FB_Alarm_Test): 1, 8, 15, 19, 21, 23
- `tests/POUs/Suites/FB_Alarm_Test/ActivateGoesActiveUnack.method.impl.st` (FB_Alarm_Test): 1, 4, 5, 8, 9, 10, 11, 12, 13, 15
- `tests/POUs/Suites/FB_Alarm_Test/ActiveAckReturnGoesNormal.method.impl.st` (FB_Alarm_Test): 1, 9, 10, 12, 13, 14, 16
- `tests/POUs/Suites/FB_Alarm_Test/ActiveWhileShelvedFollowsCondition.method.impl.st` (FB_Alarm_Test): 1, 7, 9, 10, 11, 13, 14, 16
- `tests/POUs/Suites/FB_Alarm_Test/FB_Alarm_Test.decl.st` (FB_Alarm_Test): 8
- `tests/POUs/Suites/FB_Alarm_Test/InterfacePropertiesMatchOutputs.method.impl.st` (FB_Alarm_Test): 1, 6, 7, 8, 9, 10, 11, 14, 16
- `tests/POUs/Suites/FB_Alarm_Test/NoTimeSourceFallsBackToSystemTime.method.impl.st` (FB_Alarm_Test): 1, 4, 5, 10, 12
- `tests/POUs/Suites/FB_Alarm_Test/OffDelayHoldsActive.method.impl.st` (FB_Alarm_Test): 1, 5, 12, 13, 16, 18
- `tests/POUs/Suites/FB_Alarm_Test/OnDelayShortConditionNoAlarm.method.impl.st` (FB_Alarm_Test): 1, 15, 16, 23, 26, 28
- `tests/POUs/Suites/FB_Alarm_Test/OosEntryClearsUnackReannunciatesOnExit.method.impl.st` (FB_Alarm_Test): 1, 5, 6, 7, 9, 15, 17
- `tests/POUs/Suites/FB_Alarm_Test/OosOffWithSuppressActiveGoesSuppressed.method.impl.st` (FB_Alarm_Test): 1, 4, 8, 11, 13
- `tests/POUs/Suites/FB_Alarm_Test/OutOfServiceOverridesShelve.method.impl.st` (FB_Alarm_Test): 1, 10, 11, 12, 13, 17, 18, 19, 23, 24, 27, 30
- `tests/POUs/Suites/FB_Alarm_Test/PriorityChangeWhileActiveNoEvent.method.impl.st` (FB_Alarm_Test): 1, 7, 8, 9, 11
- `tests/POUs/Suites/FB_Alarm_Test/PriorityNoneCancelsShelve.method.impl.st` (FB_Alarm_Test): 1, 7, 12, 13, 14, 15, 21, 23, 24, 26
- `tests/POUs/Suites/FB_Alarm_Test/PriorityNoneNeverActivates.method.impl.st` (FB_Alarm_Test): 1, 13, 14, 15, 16, 18
- `tests/POUs/Suites/FB_Alarm_Test/PriorityNoneToMediumActiveConditionActivates.method.impl.st` (FB_Alarm_Test): 1, 10, 12, 22, 25, 27
- `tests/POUs/Suites/FB_Alarm_Test/PriorityOutOfEnumTreatedAsMedium.method.impl.st` (FB_Alarm_Test): 1, 9, 11, 13, 15
- `tests/POUs/Suites/FB_Alarm_Test/PriorityReenabledOnDelayCountsFromEnabling.method.impl.st` (FB_Alarm_Test): 1, 9, 21, 22, 25, 27
- `tests/POUs/Suites/FB_Alarm_Test/ReactivateFromRtnUnackGoesActiveUnack.method.impl.st` (FB_Alarm_Test): 1, 8, 10, 11, 12, 14
- `tests/POUs/Suites/FB_Alarm_Test/ReshelveRestartsTimer.method.impl.st` (FB_Alarm_Test): 1, 9, 10, 11, 13

… и ещё 410 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Тип <code>LTIME</code> — 56</summary>

Библиотека plc-process-lib:

- `src/DUTs/Alarm/ST_AlarmEvent.dut.st` (ST_AlarmEvent): 14
- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 33, 41
- `src/Interfaces/I_TimeSource/Now.method.decl.st` (I_TimeSource): 2
- `src/POUs/Alarm/FB_Alarm/FB_Alarm.decl.st` (FB_Alarm): 28, 38, 40
- `src/POUs/Base/FB_DeviceBase/FB_DeviceBase.decl.st` (FB_DeviceBase): 19, 20, 21
- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 48, 69
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 67, 68, 74, 75, 98, 99, 100, 101
- `src/POUs/Devices/FB_Valve/FB_Valve.decl.st` (FB_Valve): 65
- `src/POUs/PRG_Main/PRG_Main.decl.st` (PRG_Main): 15
- `src/POUs/Time/FB_Delay/FB_Delay.decl.st` (FB_Delay): 23, 28, 29, 30
- `src/POUs/Time/FB_FakeTime/AdvanceL.method.decl.st` (FB_FakeTime): 4
- `src/POUs/Time/FB_FakeTime/FB_FakeTime.decl.st` (FB_FakeTime): 11
- `src/POUs/Time/FB_FakeTime/Now.method.decl.st` (FB_FakeTime): 2
- `src/POUs/Time/FB_FakeTime/SetNow.method.decl.st` (FB_FakeTime): 4
- `src/POUs/Time/FB_SystemTime/Now.method.decl.st` (FB_SystemTime): 3
- `src/POUs/Util/FB_StartsWindow/Count.method.decl.st` (FB_StartsWindow): 5
- `src/POUs/Util/FB_StartsWindow/FB_StartsWindow.decl.st` (FB_StartsWindow): 10
- `src/POUs/Util/FB_StartsWindow/Register.method.decl.st` (FB_StartsWindow): 4
- `src/POUs/Util/FB_StartsWindow/TimeToFree.method.decl.st` (FB_StartsWindow): 3, 5
- `src/POUs/Util/F_LTimeToSec/F_LTimeToSec.decl.st` (F_LTimeToSec): 8
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 56
- `tests/POUs/Suites/FB_Alarm_Test/TransitionSendsEventToSink.method.decl.st` (FB_Alarm_Test): 10
- `tests/POUs/Suites/FB_Runtime_Test/FB_Runtime_Test.decl.st` (FB_Runtime_Test): 18
- `tests/POUs/Suites/FB_Runtime_Test/LTimeMonotonicAcrossTaskCycles.method.decl.st` (FB_Runtime_Test): 9
- `tests/POUs/Suites/FB_Runtime_Test/LTimeResolutionAtMost1us.method.decl.st` (FB_Runtime_Test): 7, 8, 9

… и ещё 7 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Литералы <code>LTIME#</code>, <code>LT#</code> — 99</summary>

Библиотека plc-process-lib:

- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 33, 41
- `src/POUs/Base/FB_DeviceBase/BeginCycle.method.impl.st` (FB_DeviceBase): 6
- `src/POUs/Control/FB_PID/FB_PID.impl.st` (FB_PID): 115
- `src/POUs/Devices/FB_Motor/FB_Motor.impl.st` (FB_Motor): 122, 126, 347, 403, 408
- `src/POUs/Devices/FB_Valve/CountOperations.method.impl.st` (FB_Valve): 13, 14
- `src/POUs/Time/FB_FakeTime/FB_FakeTime.decl.st` (FB_FakeTime): 11
- `src/POUs/Util/FB_StartsWindow/TimeToFree.method.impl.st` (FB_StartsWindow): 3
- `tests/POUs/Suites/FB_Alarm_Test/NoTimeSourceFallsBackToSystemTime.method.impl.st` (FB_Alarm_Test): 5
- `tests/POUs/Suites/FB_Alarm_Test/TimeBackwardsShelveRemainNotExtended.method.impl.st` (FB_Alarm_Test): 3, 7
- `tests/POUs/Suites/FB_AnalogInput_Test/TimeBackwardsFilterHoldsWithoutJump.method.impl.st` (FB_AnalogInput_Test): 10
- `tests/POUs/Suites/FB_Common_Test/TestSinkRecordsEventsInOrder.method.impl.st` (FB_Common_Test): 8, 15, 29
- `tests/POUs/Suites/FB_DeviceBase_Test/BeginCycleDtZeroOnFirstCallThenFromTimeSource.method.impl.st` (FB_DeviceBase_Test): 4, 7, 8, 10, 13
- `tests/POUs/Suites/FB_DeviceBase_Test/NoTimeSourceUsesSystemTime.method.impl.st` (FB_DeviceBase_Test): 6, 7
- `tests/POUs/Suites/FB_Motor_Test/TimeBackwardsNoFaultNoCountJump.method.impl.st` (FB_Motor_Test): 9
- `tests/POUs/Suites/FB_Pid_Test/TimeBackwardsInitStepNoJump.method.impl.st` (FB_Pid_Test): 19
- `tests/POUs/Suites/FB_Runtime_Test/LTimeMonotonicAcrossTaskCycles.method.impl.st` (FB_Runtime_Test): 13, 16, 17
- `tests/POUs/Suites/FB_Runtime_Test/LTimeResolutionAtMost1us.method.decl.st` (FB_Runtime_Test): 9
- `tests/POUs/Suites/FB_Runtime_Test/LTimeResolutionAtMost1us.method.impl.st` (FB_Runtime_Test): 18
- `tests/POUs/Suites/FB_Runtime_Test/LTimeSubtractionWrapsWhenNegative.method.decl.st` (FB_Runtime_Test): 5, 6
- `tests/POUs/Suites/FB_Runtime_Test/LTimeSubtractionWrapsWhenNegative.method.impl.st` (FB_Runtime_Test): 4
- `tests/POUs/Suites/FB_Runtime_Test/LkgCopy300MotorCfgBelow1ms.method.impl.st` (FB_Runtime_Test): 11
- `tests/POUs/Suites/FB_Time_Test/FakeTimeAdvanceAddsStep.method.impl.st` (FB_Time_Test): 6, 9
- `tests/POUs/Suites/FB_Time_Test/FakeTimeAdvanceLSubMsAndLongSteps.method.impl.st` (FB_Time_Test): 5, 7, 9, 10
- `tests/POUs/Suites/FB_Time_Test/FakeTimeSetNowSetsValue.method.impl.st` (FB_Time_Test): 3, 4, 5, 6
- `tests/POUs/Suites/FB_Time_Test/FakeTimeStartsAtOneHour.method.impl.st` (FB_Time_Test): 3

… и ещё 12 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Преобразования <code>*_TO_LTIME</code>, <code>LTIME_TO_*</code> — 19</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/FB_Alarm.impl.st` (FB_Alarm): 56
- `src/POUs/Alarm/FB_Alarm/UpdateShelve.method.impl.st` (FB_Alarm): 6, 7, 27
- `src/POUs/Control/FB_PID/FB_PID.impl.st` (FB_PID): 111, 115
- `src/POUs/Devices/FB_Motor/FB_Motor.impl.st` (FB_Motor): 67, 68, 118, 225, 347, 355, 357, 411, 413
- `src/POUs/Time/FB_Delay/FB_Delay.impl.st` (FB_Delay): 16, 28
- `src/POUs/Time/FB_FakeTime/Advance.method.impl.st` (FB_FakeTime): 1
- `src/POUs/Util/F_LTimeToSec/F_LTimeToSec.impl.st` (F_LTimeToSec): 1

</details>

<details><summary><code>LINT</code>, <code>ULINT</code>, <code>LWORD</code> — 2</summary>

Библиотека plc-process-lib:

- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 112, 114

</details>

<details><summary>Структуры (<code>STRUCT</code>) — 28</summary>

Библиотека plc-process-lib:

- `src/DUTs/Alarm/ST_AlarmCfg.dut.st` (ST_AlarmCfg): 7
- `src/DUTs/Alarm/ST_AlarmEvent.dut.st` (ST_AlarmEvent): 7
- `src/DUTs/AnalogInput/ST_AiLimitCfg.dut.st` (ST_AiLimitCfg): 7
- `src/DUTs/AnalogInput/ST_AnalogInputCfg.dut.st` (ST_AnalogInputCfg): 8
- `src/DUTs/AnalogInput/ST_AnalogInputCmd.dut.st` (ST_AnalogInputCmd): 6
- `src/DUTs/AnalogInput/ST_AnalogInputSts.dut.st` (ST_AnalogInputSts): 7
- `src/DUTs/Common/ST_DeviceCmd.dut.st` (ST_DeviceCmd): 7
- `src/DUTs/Common/ST_DeviceRetain.dut.st` (ST_DeviceRetain): 10
- `src/DUTs/Common/ST_DeviceSts.dut.st` (ST_DeviceSts): 8
- `src/DUTs/ControlValve/ST_ControlValveCfg.dut.st` (ST_ControlValveCfg): 8
- `src/DUTs/ControlValve/ST_ControlValveCmd.dut.st` (ST_ControlValveCmd): 6
- `src/DUTs/ControlValve/ST_ControlValveSts.dut.st` (ST_ControlValveSts): 7
- `src/DUTs/DigitalInput/ST_DigitalInputCfg.dut.st` (ST_DigitalInputCfg): 8
- `src/DUTs/DigitalInput/ST_DigitalInputCmd.dut.st` (ST_DigitalInputCmd): 6
- `src/DUTs/DigitalInput/ST_DigitalInputSts.dut.st` (ST_DigitalInputSts): 8
- `src/DUTs/Motor/ST_MotorCfg.dut.st` (ST_MotorCfg): 9
- `src/DUTs/Motor/ST_MotorCmd.dut.st` (ST_MotorCmd): 6
- `src/DUTs/Motor/ST_MotorSts.dut.st` (ST_MotorSts): 7
- `src/DUTs/Motor/ST_VfdCfg.dut.st` (ST_VfdCfg): 8
- `src/DUTs/Pid/ST_PidCfg.dut.st` (ST_PidCfg): 8
- `src/DUTs/Pid/ST_PidCmd.dut.st` (ST_PidCmd): 6
- `src/DUTs/Pid/ST_PidSts.dut.st` (ST_PidSts): 7
- `src/DUTs/Valve/ST_ValveCfg.dut.st` (ST_ValveCfg): 8
- `src/DUTs/Valve/ST_ValveCmd.dut.st` (ST_ValveCmd): 6
- `src/DUTs/Valve/ST_ValveSts.dut.st` (ST_ValveSts): 7

… и ещё 3 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Объединения (<code>UNION</code>) — 5</summary>

Библиотека plc-process-lib:

- `src/DUTs/Common/U_RealBits.dut.st` (U_RealBits): 7
- `tests/DUTs/AiDi/U_AiDiTestEnum.dut.st` (U_AiDiTestEnum): 9
- `tests/DUTs/Pid/U_TestPidEnumInt.dut.st` (U_TestPidEnumInt): 8
- `tests/DUTs/TestDevice/U_TestEnumInt.dut.st` (U_TestEnumInt): 8
- `tests/DUTs/Valves/U_TestValveEnum.dut.st` (U_TestValveEnum): 10

</details>

<details><summary>Перечисления — 24</summary>

Библиотека plc-process-lib:

- `src/DUTs/Alarm/E_AlarmEventReason.dut.st` (E_AlarmEventReason): 7
- `src/DUTs/Alarm/E_AlarmPriority.dut.st` (E_AlarmPriority): 8
- `src/DUTs/Alarm/E_AlarmState.dut.st` (E_AlarmState): 9
- `src/DUTs/AnalogInput/E_AiAlarm.dut.st` (E_AiAlarm): 7
- `src/DUTs/AnalogInput/E_AiFailValue.dut.st` (E_AiFailValue): 7
- `src/DUTs/AnalogInput/E_AiInputType.dut.st` (E_AiInputType): 7
- `src/DUTs/AnalogInput/E_AiSignalState.dut.st` (E_AiSignalState): 8
- `src/DUTs/Common/E_CmdResult.dut.st` (E_CmdResult): 8
- `src/DUTs/Common/E_DeviceMode.dut.st` (E_DeviceMode): 9
- `src/DUTs/Common/E_DeviceType.dut.st` (E_DeviceType): 8
- `src/DUTs/Common/E_Ne107Status.dut.st` (E_Ne107Status): 9
- `src/DUTs/ControlValve/E_CvAlarm.dut.st` (E_CvAlarm): 7
- `src/DUTs/ControlValve/E_CvFaultAction.dut.st` (E_CvFaultAction): 7
- `src/DUTs/DigitalInput/E_DiAlarm.dut.st` (E_DiAlarm): 7
- `src/DUTs/DigitalInput/E_DiFailValue.dut.st` (E_DiFailValue): 7
- `src/DUTs/Motor/E_MotorAlarm.dut.st` (E_MotorAlarm): 7
- `src/DUTs/Motor/E_MotorState.dut.st` (E_MotorState): 7
- `src/DUTs/Pid/E_PidAction.dut.st` (E_PidAction): 7
- `src/DUTs/Pid/E_PidAlarm.dut.st` (E_PidAlarm): 7
- `src/DUTs/Pid/E_PidPvFailAction.dut.st` (E_PidPvFailAction): 7
- `src/DUTs/Valve/E_ValveAlarm.dut.st` (E_ValveAlarm): 7
- `src/DUTs/Valve/E_ValveSafePos.dut.st` (E_ValveSafePos): 7
- `src/DUTs/Valve/E_ValveState.dut.st` (E_ValveState): 7
- `src/DUTs/Valve/E_ValveType.dut.st` (E_ValveType): 7

</details>

<details><summary>Перечисления с базовым типом (<code>(…) INT</code>) — 24</summary>

Библиотека plc-process-lib:

- `src/DUTs/Alarm/E_AlarmEventReason.dut.st` (E_AlarmEventReason): 7
- `src/DUTs/Alarm/E_AlarmPriority.dut.st` (E_AlarmPriority): 8
- `src/DUTs/Alarm/E_AlarmState.dut.st` (E_AlarmState): 9
- `src/DUTs/AnalogInput/E_AiAlarm.dut.st` (E_AiAlarm): 7
- `src/DUTs/AnalogInput/E_AiFailValue.dut.st` (E_AiFailValue): 7
- `src/DUTs/AnalogInput/E_AiInputType.dut.st` (E_AiInputType): 7
- `src/DUTs/AnalogInput/E_AiSignalState.dut.st` (E_AiSignalState): 8
- `src/DUTs/Common/E_CmdResult.dut.st` (E_CmdResult): 8
- `src/DUTs/Common/E_DeviceMode.dut.st` (E_DeviceMode): 9
- `src/DUTs/Common/E_DeviceType.dut.st` (E_DeviceType): 8
- `src/DUTs/Common/E_Ne107Status.dut.st` (E_Ne107Status): 9
- `src/DUTs/ControlValve/E_CvAlarm.dut.st` (E_CvAlarm): 7
- `src/DUTs/ControlValve/E_CvFaultAction.dut.st` (E_CvFaultAction): 7
- `src/DUTs/DigitalInput/E_DiAlarm.dut.st` (E_DiAlarm): 7
- `src/DUTs/DigitalInput/E_DiFailValue.dut.st` (E_DiFailValue): 7
- `src/DUTs/Motor/E_MotorAlarm.dut.st` (E_MotorAlarm): 7
- `src/DUTs/Motor/E_MotorState.dut.st` (E_MotorState): 7
- `src/DUTs/Pid/E_PidAction.dut.st` (E_PidAction): 7
- `src/DUTs/Pid/E_PidAlarm.dut.st` (E_PidAlarm): 7
- `src/DUTs/Pid/E_PidPvFailAction.dut.st` (E_PidPvFailAction): 7
- `src/DUTs/Valve/E_ValveAlarm.dut.st` (E_ValveAlarm): 7
- `src/DUTs/Valve/E_ValveSafePos.dut.st` (E_ValveSafePos): 7
- `src/DUTs/Valve/E_ValveState.dut.st` (E_ValveState): 7
- `src/DUTs/Valve/E_ValveType.dut.st` (E_ValveType): 7

</details>

<details><summary><code>VAR_IN_OUT</code> — 22</summary>

Библиотека plc-process-lib:

- `src/POUs/Base/FB_DeviceBase/FinishCycle.method.decl.st` (FB_DeviceBase): 12
- `src/POUs/Base/FB_DeviceBase/ProcessMode.method.decl.st` (FB_DeviceBase): 11
- `src/POUs/Base/FB_DeviceBase/RunAlarms.method.decl.st` (FB_DeviceBase): 9
- `src/POUs/Base/FB_DeviceBase/SwitchRemoteMode.method.decl.st` (FB_DeviceBase): 8
- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 22
- `src/POUs/Devices/FB_AnalogInput/CallLimit.method.decl.st` (FB_AnalogInput): 11
- `src/POUs/Devices/FB_AnalogInput/FB_AnalogInput.decl.st` (FB_AnalogInput): 18
- `src/POUs/Devices/FB_ControlValve/FB_ControlValve.decl.st` (FB_ControlValve): 20
- `src/POUs/Devices/FB_DigitalInput/FB_DigitalInput.decl.st` (FB_DigitalInput): 14
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 23
- `src/POUs/Devices/FB_Valve/CountOperations.method.decl.st` (FB_Valve): 4
- `src/POUs/Devices/FB_Valve/FB_Valve.decl.st` (FB_Valve): 27
- `src/POUs/Devices/FB_Valve/HandleCommands.method.decl.st` (FB_Valve): 6
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 37
- `tests/POUs/Suites/FB_AnalogInput_Test/SetAlarmPriority.method.decl.st` (FB_AnalogInput_Test): 3
- `tests/POUs/Suites/FB_AnalogInput_Test/SetLimit.method.decl.st` (FB_AnalogInput_Test): 3
- `tests/POUs/Suites/FB_DeviceBase_Test/SetSlotCfg.method.decl.st` (FB_DeviceBase_Test): 3
- `tests/POUs/Suites/FB_DigitalInput_Test/SetAlarmPriority.method.decl.st` (FB_DigitalInput_Test): 3
- `tests/POUs/Suites/FB_MotorVfd_Test/SpinVfd.method.decl.st` (FB_MotorVfd_Test): 4
- `tests/POUs/Suites/FB_Motor_Test/SetSlotPriority.method.decl.st` (FB_Motor_Test): 3
- `tests/POUs/Suites/FB_Motor_Test/Spin.method.decl.st` (FB_Motor_Test): 4
- `tests/POUs/Suites/FB_Runtime_Test/CallDevice.method.decl.st` (FB_Runtime_Test): 3

</details>

<details><summary><code>VAR_IN_OUT CONSTANT</code> — 23</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_AlarmSink/OnAlarmEvent.method.decl.st` (I_AlarmSink): 3
- `src/POUs/Base/FB_DeviceBase/CheckAlarmCfg.method.decl.st` (FB_DeviceBase): 4
- `src/POUs/Base/FB_DeviceBase/RunAlarms.method.decl.st` (FB_DeviceBase): 12
- `src/POUs/Control/FB_PID/CheckConfig.method.decl.st` (FB_PID): 4
- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 26
- `src/POUs/Devices/FB_AnalogInput/CheckConfig.method.decl.st` (FB_AnalogInput): 4
- `src/POUs/Devices/FB_AnalogInput/FB_AnalogInput.decl.st` (FB_AnalogInput): 21
- `src/POUs/Devices/FB_ControlValve/CheckConfig.method.decl.st` (FB_ControlValve): 4
- `src/POUs/Devices/FB_ControlValve/FB_ControlValve.decl.st` (FB_ControlValve): 24
- `src/POUs/Devices/FB_DigitalInput/CheckConfig.method.decl.st` (FB_DigitalInput): 4
- `src/POUs/Devices/FB_DigitalInput/FB_DigitalInput.decl.st` (FB_DigitalInput): 17
- `src/POUs/Devices/FB_Motor/CheckConfig.method.decl.st` (FB_Motor): 4
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 27
- `src/POUs/Devices/FB_MotorVfd/CheckConfig.method.decl.st` (FB_MotorVfd): 3
- `src/POUs/Devices/FB_Valve/CheckConfig.method.decl.st` (FB_Valve): 3
- `src/POUs/Devices/FB_Valve/FB_Valve.decl.st` (FB_Valve): 31
- `tests/POUs/Helpers/FB_TestDevice/CheckConfig.method.decl.st` (FB_TestDevice): 3
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 41
- `tests/POUs/Helpers/FB_TestDevice/ProbeAlarmCfg.method.decl.st` (FB_TestDevice): 3
- `tests/POUs/Helpers/FB_TestSink/OnAlarmEvent.method.decl.st` (FB_TestSink): 3
- `tests/POUs/Suites/FB_MotorVfd_Test/SpinVfd.method.decl.st` (FB_MotorVfd_Test): 10
- `tests/POUs/Suites/FB_Motor_Test/Spin.method.decl.st` (FB_Motor_Test): 10
- `tests/POUs/Suites/FB_Runtime_Test/CallDevice.method.decl.st` (FB_Runtime_Test): 8

</details>

<details><summary><code>VAR_TEMP</code> — 10</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/FB_Alarm.decl.st` (FB_Alarm): 45
- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 61
- `src/POUs/Devices/FB_AnalogInput/FB_AnalogInput.decl.st` (FB_AnalogInput): 54
- `src/POUs/Devices/FB_ControlValve/FB_ControlValve.decl.st` (FB_ControlValve): 56
- `src/POUs/Devices/FB_DigitalInput/FB_DigitalInput.decl.st` (FB_DigitalInput): 32
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 84
- `src/POUs/Devices/FB_Valve/FB_Valve.decl.st` (FB_Valve): 92
- `src/POUs/Time/FB_Delay/FB_Delay.decl.st` (FB_Delay): 27
- `src/POUs/Util/FB_LimitMonitor/FB_LimitMonitor.decl.st` (FB_LimitMonitor): 24
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 64

</details>

<details><summary>Локальные константы (<code>VAR CONSTANT</code>) — 4</summary>

Библиотека plc-process-lib:

- `tests/POUs/Helpers/FB_FopdtModel/FB_FopdtModel.decl.st` (FB_FopdtModel): 10
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 13
- `tests/POUs/Helpers/FB_TestSink/FB_TestSink.decl.st` (FB_TestSink): 8
- `tests/POUs/Suites/FB_Runtime_Test/FB_Runtime_Test.decl.st` (FB_Runtime_Test): 12

</details>

<details><summary><code>VAR_GLOBAL CONSTANT</code> — 8</summary>

Библиотека plc-process-lib:

- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 11, 58, 70, 101, 116, 154, 187, 214

</details>

<details><summary>Оператор <code>LTIME()</code> (монотонное время) — 1</summary>

Библиотека plc-process-lib:

- `src/POUs/Time/FB_SystemTime/Now.method.impl.st` (FB_SystemTime): 1

</details>

<details><summary><code>SIZEOF</code> — 31</summary>

Библиотека plc-process-lib:

- `tests/POUs/Suites/FB_Common_Test/SizeOfAlarmCfgIs16.method.impl.st` (FB_Common_Test): 3, 4
- `tests/POUs/Suites/FB_Common_Test/SizeOfCfgMatchesReference.method.impl.st` (FB_Common_Test): 3, 4, 5, 6, 7, 8, 9
- `tests/POUs/Suites/FB_Common_Test/SizeOfCmdMatchesReference.method.impl.st` (FB_Common_Test): 3, 4, 5, 6, 7, 8, 9
- `tests/POUs/Suites/FB_Common_Test/SizeOfDeviceRetainIs36.method.impl.st` (FB_Common_Test): 3
- `tests/POUs/Suites/FB_Common_Test/SizeOfStsMatchesRegisterMap.method.impl.st` (FB_Common_Test): 3, 4, 5, 6, 7, 8, 9
- `tests/POUs/Suites/FB_DeviceBase_Test/AlarmSlotArraysMatchDevAlarmsMax.method.impl.st` (FB_DeviceBase_Test): 3, 4, 5, 7, 9
- `tests/POUs/Suites/FB_Util_Test/StartsWindowRingCapacityMatchesConst.method.impl.st` (FB_Util_Test): 3

</details>

<details><summary>Задачи из <code>tools/codesys/config.json</code> — 2</summary>

Библиотека plc-process-lib:

- `tools/codesys/config.json` (normal): 69, 81

</details>

## Ссылки

### Факты

| Факт | Кратко | Где сказано | Источник |
|---|---|---|---|
| <a id="ref-f04"></a>F04 | Описание устройства REGUL R500 71-W совместимо с 3.5.17.*; плейсхолдеры системных библиотек разрешаются на 3.5.17.0 (SysFile, SysDir, SysTime, SysTimeRtc, CAA File, CAA Memory, CAA SerialCom, CmpLog, CmpApp, CmpIecTask и др.); задачи: приоритет по умолчанию 2, максимальный 15, до 100 задач | пакет 1.7.2.6, REGUL R500 71-W.devdesc.xml | [ссылка](https://reglab.ru/upload/iblock/0fd/bkk3sngi1qu0kz62c3j1so8iykr78fr6/RegLab_Ltd_Regul_1.7.2.6.package) |
| <a id="ref-f19"></a>F19 | POU может быть программой, функцией, ФБ, методом, действием, интерфейсом, DUT | DPA-302 v2.20, с. 38, 43 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f20"></a>F20 | Пример вендора: ФБ `IMPLEMENTS` трёх интерфейсов с callback-методами и параметрами `POINTER TO` | DPA-302 v2.20, прил. И, с. 309–313 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f21"></a>F21 | В примере вендора — `METHOD PUBLIC`, реализация библиотечного интерфейса, свойства у ФБ драйвера | DPA-302.2 v2.11 (IEC 101/104), с. 28, 30 | [ссылка](https://reglab.ru/upload/iblock/a6f/cu6npbpdnappv49sj4a0us8zujoroxp3/Nastroyka-IEC_104_101-User-Guide_DPA_302_2_v2.11_rus.pdf) |
| <a id="ref-f22"></a>F22 | Курс описывает `FB_Init` и методы ФБ; у библиотечных ФБ есть `FB_init` с параметрами и свойство с Get/Set | курс, 5.10; DPA-302 v2.20, с. 388, 397 | [ссылка](https://reglab.ru/upload/materialy-kursa/funktsionalnyj_blok_fb_sin_x.htm) |
| <a id="ref-f23"></a>F23 | `EXTENDS` для ФБ, `SUPER^`, `THIS^`, `ABSTRACT`, `FINAL`, `PRIVATE/PROTECTED/INTERNAL`, наследование интерфейсов, `__QUERYINTERFACE` в документации вендора не найдены (DPA-302*, курс, форум) | отсутствие в документах; работа в Astra.IDE — проверить вручную | первоисточника нет (вывод исследования) |
| <a id="ref-f25"></a>F25 | `{attribute 'qualified_only'}` — к переменным GVL обращаются только с именем списка | курс, 5.7 | [ссылка](https://reglab.ru/upload/materialy-kursa/atribut__qualified_only_.htm) |
| <a id="ref-f29"></a>F29 | `'strict'`, `'call_after_init'`, `'hide'`, `'no_check'`, `'init_namespace'`, `'monitoring'` и `{IF defined(...)}` в документации не найдены | DPA-302 v2.20, с. 43 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f30"></a>F30 | В таблицах OPC UA есть `LWORD`, `LINT/ULINT`, `WSTRING` и структура `ua_var_ltime` для `LTIME` | DPA-302.6 v1.7, с. 7–10 | [ссылка](https://reglab.ru/upload/iblock/57b/dvvplmt0qby4duccefw4vyi9j3u59ziu/OPC_UA_User_Guide_DPA_302_6_v1_7_rus.pdf) |
| <a id="ref-f32"></a>F32 | DUT: структура, перечисление, псевдоним, объединение; `BIT` — в структурах и ФБ, не в массивах | курс, 5.8 | [ссылка](https://reglab.ru/upload/materialy-kursa/strukturnye_tipy.htm) |
| <a id="ref-f33"></a>F33 | Перечисления с явными значениями и `VAR_STAT` поддерживаются (видны в OPC UA) | DPA-302.6 v1.7, с. 12–14 | [ссылка](https://reglab.ru/upload/iblock/57b/dvvplmt0qby4duccefw4vyi9j3u59ziu/OPC_UA_User_Guide_DPA_302_6_v1_7_rus.pdf) |
| <a id="ref-f34"></a>F34 | Перечисления с базовым типом, `STRUCT … EXTENDS`, `LDATE/LTOD/LDT`, литералы и арифметика `LTIME` в документации не описаны | отсутствие в документах; проверить вручную | первоисточника нет (вывод исследования) |
| <a id="ref-f47"></a>F47 | PLCopenXML в CODESYS — подмножество; при экспорте VAR_GLOBAL и VAR_GLOBAL CONSTANT нельзя держать в одном списке | CODESYS Online Help, Exporting and Importing Projects; Command: Export PLCopenXML | [ссылка](https://content.helpme-codesys.com/en/CODESYS%20Development%20System/_cds_cmd_export_plcopenxml.html) |
| <a id="ref-f50"></a>F50 | В учебных проектах вендора используются Standard (`R_TRIG`, `LEN`), Standard64 (`WLEN`) и Util | курс, 4.14, 5.13, 17.16 | [ссылка](https://reglab.ru/upload/materialy-kursa/okno_programmnogo_bloka_s_kodom_na_yazyke_st.htm) |
| <a id="ref-f52"></a>F52 | Время: SysTime, SysTimeRtc, PsTime (`PsTimeGetUtcTimeNs` — UTC в нс, `ULINT`) | курс, 15.2; DPA-302 v2.20, с. 234, 390 | [ссылка](https://reglab.ru/upload/materialy-kursa/biblioteki_dlya_raboty_s_datoj_i_vremenem.htm) |
| <a id="ref-f73"></a>F73 | coUnit 1.2.0.0 ссылается на 16 библиотек, в том числе Breakpoint Logging Functions 3.5.5.0 (фиксированная версия), IECStringUtils, Base Interfaces | по исходникам coUnit (forge.codesys.com/lib/counit); наличие в Astra.IDE — проверить вручную | [ссылка](https://forge.codesys.com/lib/counit/) |
| <a id="ref-f85"></a>F85 | В патче 1.7.2.5 добавлен запрет на ссылки и указатели в символьной конфигурации | reglab.ru/soft, «Патч 1.7.2.5» | [ссылка](https://reglab.ru/soft/) |

### Риски

| Риск | Кратко |
|---|---|
| <a id="ref-r8"></a>R8 | OPC UA: ФБ с REFERENCE/POINTER (возможно, и с интерфейсными переменными) ломают символьную конфигурацию — фасад GVL с плоскими типами |
| <a id="ref-r13"></a>R13 | Приоритеты задач REGUL 0–15, 0 и 1 зарезервированы — таблица соответствия задач |
| <a id="ref-r15"></a>R15 | Наследование ФБ не подтверждено — композиция и интерфейсы, каждая правка с `// PORT:` |
| <a id="ref-r16"></a>R16 | Атрибуты strict, call_after_init не описаны — проверить компиляцией и поведением |
| <a id="ref-r17"></a>R17 | Перечисления с базовым типом, STRUCT EXTENDS не описаны — явные значения, композиция |
| <a id="ref-r18"></a>R18 | coUnit может не собраться — тесты логики в CODESYS 3.5.17.30, на REGUL — интеграционные |
| <a id="ref-r20"></a>R20 | Источник времени `Now() : LTIME` — реализация на `PsTimeGetUtcTimeNs`/`SysTimeRtc` |

### Пункты чек-листа «проверить вручную»

Полный чек-лист с той же нумерацией — [раздел 9 чек-листа миграции](migration_checklist.md#9-проверить-вручную).

| Пункт | Что проверить |
|---|---|
| <a id="ref-b3"></a>B3 | Импорт PLCopenXML из CODESYS 3.5.17.30: методы, свойства, интерфейсы, EXTENDS/IMPLEMENTS, атрибуты, PersistentVars |
| <a id="ref-c1"></a>C1 | `FUNCTION_BLOCK FB_B EXTENDS FB_A` и вызов `SUPER^.Method()` |
| <a id="ref-c2"></a>C2 | `THIS^`, `ABSTRACT` (ФБ, метод, свойство), `FINAL` |
| <a id="ref-c3"></a>C3 | Спецификаторы `PRIVATE`, `PROTECTED`, `INTERNAL`; свойство в пользовательском ФБ |
| <a id="ref-c4"></a>C4 | Наследование интерфейсов, `__QUERYINTERFACE`, `__QUERYPOINTER` |
| <a id="ref-c5"></a>C5 | `{attribute 'strict'}`: неквалифицированное обращение даёт ошибку |
| <a id="ref-c7"></a>C7 | Перечисление с базовым типом |
| <a id="ref-c8"></a>C8 | `STRUCT ... EXTENDS`; `UNION` в составе структуры |
| <a id="ref-c11"></a>C11 | `LTIME`: литералы, арифметика, преобразования, таймеры на LTIME |
| <a id="ref-c13"></a>C13 | `VAR_IN_OUT` (в том числе `CONSTANT`) с массивами и строками |
| <a id="ref-c14"></a>C14 | `{attribute 'linkalways'}` у GVL тестов: GVL без ссылок из кода попадает в приложение (пункт добавлен в чек-лист миграции по итогам инвентаризации) |
| <a id="ref-g4"></a>G4 | Ошибка символьной конфигурации на ФБ с REFERENCE/POINTER и интерфейсными переменными |
| <a id="ref-h2"></a>H2 | Установить coUnit 1.2.0.0 и собрать тестовый проект |
| <a id="ref-h3"></a>H3 | Прогон coUnit на ВПЛК: результаты и путь к xUnit-файлу |
| <a id="ref-j1"></a>J1 | Допустимые приоритеты задач на выбранном ЦП, сторожевой таймер, системные задачи |

### Разделы исследования

- <a id="ref-29"></a>§2.9 — раздел 2.9 исследования (Modbus): `ModbusUserRequest2` с буфером `ADR`/`SIZEOF` (DPA-302.1 v1.7)
