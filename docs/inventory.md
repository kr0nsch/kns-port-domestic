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
| Библиотека plc-process-lib | `../plc-process-lib` | `v1.0.0` = `bd9df2a` (2026-10-19) | src, tests | 116 | — |
| Флагман kns-pump-station | `../kns-pump-station` | `505ce149a0e0fb72b5cce79e72876722abeba9d0` = `505ce14` (2026-10-19) | src, tests | 121 | — |

## Объём кода

| Источник | Каталог | DUT | GVL | PVL | интерфейсы | FUNCTION | FUNCTION_BLOCK | PROGRAM | Методы | Свойства | Файлов | Строк | Строк кода |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Библиотека plc-process-lib | `src` | 50 | 2 | 0 | 7 | 6 | 14 | 1 | 77 | 38 | 322 | 5716 | 4357 |
| Библиотека plc-process-lib | `tests` | 7 | 7 | 0 | 0 | 0 | 21 | 1 | 474 | 2 | 1010 | 17718 | 15134 |
| Флагман kns-pump-station | `src` | 27 | 12 | 1 | 1 | 10 | 26 | 8 | 43 | 3 | 220 | 7792 | 6405 |
| Флагман kns-pump-station | `tests` | 0 | 3 | 0 | 0 | 0 | 32 | 1 | 347 | 14 | 791 | 11696 | 9716 |

## Шкала риска

- **высокий** — у вендора не подтверждено, а при отказе нужна переделка структуры кода; или известное ограничение REGUL, которое требует правки кода.
- **средний** — у вендора не описано, но есть в базе CODESYS 3.5.17; проверить пробной компиляцией (пункт чек-листа), при отказе правка локальная.
- **низкий** — подтверждено документацией вендора; правки не ожидаются.
- **нет** — базовый МЭК 61131-3 или к Astra.IDE не относится.

## Главные риски

Возможности со средним и высоким риском, которые используются в коде, — по убыванию риска и числа мест.

| Риск | Возможность | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Ссылки | Что делать |
|---|---|---|---|---|---|
| высокий | coUnit (юнит-тесты: `coUnit.*`, методы `Assert*`) | 0 / 3902 | 0 / 2021 | [F73](#ref-f73), [R18](#ref-r18), [H2](#ref-h2), [H3](#ref-h3) | Сначала собрать тестовый проект с coUnit (H2); при отказе тесты логики — в CODESYS 3.5.17.30, на REGUL — интеграционные сценарии и PsUnittest |
| высокий | Наследование ФБ (`FUNCTION_BLOCK … EXTENDS`) | 7 / 18 | 0 / 29 | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Первым делом — пробный импорт иерархии; при отказе — композиция и интерфейсы, правки `// PORT:` |
| высокий | Вызов базовой реализации (`SUPER^`) | 6 / 3 | — | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Вместе с `EXTENDS`; при композиции — явный вызов вложенного экземпляра |
| средний | Спецификатор `PRIVATE` | 0 / 462 | 19 / 336 | [F23](#ref-f23), [C3](#ref-c3) | Проверить компиляцией; при отказе — убрать спецификатор (доступ станет `PUBLIC`, поведение то же) |
| средний | Переменные интерфейсного типа | 8 / 74 | 46 / 19 | [F85](#ref-f85), [R8](#ref-r8), [G4](#ref-g4) | В коде — как есть; в символьную конфигурацию OPC UA не публиковать (проверить G4) |
| средний | Литералы `LTIME#`, `LT#` | 13 / 90 | 4 / 19 | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) |
| средний | Тип `LTIME` | 37 / 19 | 24 / 24 | [F30](#ref-f30), [F34](#ref-f34), [C11](#ref-c11) | Тип есть (структура OPC UA `ua_var_ltime`); арифметику проверить (C11); в OPC UA — как `ULINT` нс |
| средний | Аксессор `Get` | 38 / 2 | 3 / 14 | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойством |
| средний | Спецификатор `PROTECTED` | 50 / 5 | — | [F23](#ref-f23), [C3](#ref-c3) | Как `PRIVATE`; зависит от `EXTENDS` |
| средний | `VAR_IN_OUT CONSTANT` | 16 / 8 | 15 / 0 | [C13](#ref-c13) | Проверить (C13); при отказе — `VAR_IN_OUT` без `CONSTANT` |
| средний | `VAR_INST` | — | 0 / 39 | — | В исследовании нет: проверить компиляцией |
| средний | Свойства ФБ (`PROPERTY`) | 19 / 2 | 3 / 14 | [F22](#ref-f22), [C3](#ref-c3) | У вендора свойства показаны только у библиотечных ФБ; проверить в пользовательском ФБ (C3), при отказе — методы `GetX`/`SetX` |
| средний | Перечисления с базовым типом (`(…) INT`) | 24 / 0 | 11 / 0 | [F34](#ref-f34), [R17](#ref-r17), [C7](#ref-c7) | Проверить (C7); при отказе — без базового типа, с явными значениями |
| средний | Преобразования `*_TO_LTIME`, `LTIME_TO_*` | 19 / 0 | 11 / 4 | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) |
| средний | `{attribute 'strict'}` | 18 / 0 | 9 / 0 | [F29](#ref-f29), [R16](#ref-r16), [C5](#ref-c5) | Проверить, что неквалифицированное обращение даёт ошибку; иначе следить вручную |
| средний | Свойства интерфейсов | 19 / 0 | — | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойствами ФБ |
| средний | Оператор `LTIME()` (монотонное время) | 1 / 0 | 3 / 12 | [F52](#ref-f52), [R20](#ref-r20), [C11](#ref-c11) | Проверить на REGUL; запасной путь — `FB_TimeSource_Regul` на `PsTimeGetUtcTimeNs` или `SysTimeRtc` |
| средний | `{attribute 'linkalways'}` | 0 / 7 | 0 / 3 | [C14](#ref-c14) | В документации РегЛаб нет; проверить, что GVL без ссылок из кода попадает в приложение (C14) |
| средний | CAA File (`FILE.*`) | — | 5 / 4 | [F53](#ref-f53), [R19](#ref-r19), [C10](#ref-c10) | Проверить на ВПЛК (C10); иначе SysFile в задаче с низким приоритетом |
| средний | `POINTER TO` | — | 1 / 6 | [F31](#ref-f31), [F85](#ref-f85), [F28](#ref-f28), [R8](#ref-r8) | Как `REFERENCE TO` |
| средний | Задачи из `tools/codesys/config.json` | 2 | 4 | [F04](#ref-f04), [R13](#ref-r13), [J1](#ref-j1) | Переназначить приоритеты: на REGUL пользовательские 2–15 (ЦП I/III) или 5–15 (ЦП II) |
| средний | `THIS^` | 4 / 1 | — | [F23](#ref-f23), [C2](#ref-c2) | Проверить компиляцией; при отказе — обращение без `THIS^` |
| средний | Наследование интерфейсов (`INTERFACE … EXTENDS`) | 3 / 0 | — | [F23](#ref-f23), [C4](#ref-c4) | Проверить пробной компиляцией; при отказе — плоские интерфейсы с повтором методов |
| средний | GVL с `VAR_GLOBAL` и `VAR_GLOBAL CONSTANT` в одном объекте | — | 1 / 0 | [F47](#ref-f47) | Для экспорта PLCopenXML держать в разных списках |
| средний | `ABSTRACT` (ФБ, метод, свойство) | 1 / 0 | — | [F23](#ref-f23), [R15](#ref-r15), [C2](#ref-c2) | При отказе — интерфейс вместо абстрактного ФБ |
| средний | Объект Persistent Variables (`*.pvl.st`) | — | 1 / 0 | [F41](#ref-f41), [R11](#ref-r11), [D1](#ref-d1) | Создать «Persistent-переменные…» вручную или импортом PLCopenXML |

## ООП

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| Интерфейсы (`INTERFACE`) | объект | 7 / 0 | 1 / 0 | низкий | [F19](#ref-f19), [F20](#ref-f20), [B3](#ref-b3) | Переносить как есть; импорт интерфейсов через PLCopenXML проверить (B3) | Флагман kns-pump-station: `I_StationEventSink`; Библиотека plc-process-lib: `I_Alarm`, `I_AlarmSink`, `I_AlarmSource`, `I_Device`, `I_Motor`, `I_MotorVfd`, `I_TimeSource` |  |
| Наследование интерфейсов (`INTERFACE … EXTENDS`) | объект | 3 / 0 | — | средний | [F23](#ref-f23), [C4](#ref-c4) | Проверить пробной компиляцией; при отказе — плоские интерфейсы с повтором методов | `I_Device`, `I_Motor`, `I_MotorVfd` | `I_AlarmSource`, `I_Device`, `I_Motor` |
| Реализация интерфейсов (`IMPLEMENTS`) | POU | 6 / 1 | 3 / 3 | низкий | [F20](#ref-f20), [F21](#ref-f21) | Переносить как есть | Флагман kns-pump-station: `FB_EventLog`, `FB_FakeEventSink`, `FB_FakeMotorVfd`, `FB_ScaledClock`, `FB_StationAlarms`, `FB_TestAlarmSource`; Библиотека plc-process-lib: `FB_Alarm`, `FB_DeviceBase`, `FB_FakeTime`, `FB_Motor`, `FB_MotorVfd`, `FB_SystemTime`, `FB_TestSink` | `I_TimeSource` ×2, `PL.I_AlarmSource` ×2, `I_Alarm`, `I_AlarmSink`, `I_Device`, `I_Motor` и ещё 5 |
| Наследование ФБ (`FUNCTION_BLOCK … EXTENDS`) | ФБ | 7 / 18 | 0 / 29 | высокий | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Первым делом — пробный импорт иерархии; при отказе — композиция и интерфейсы, правки `// PORT:` | Флагман kns-pump-station: `FB_AlarmSummary_Test`, `FB_Annunciator_Test`, `FB_Ats_Test`, `FB_ControlSelector_Test`, `FB_DeviceAudit_Test`, `FB_EventLog_Test`, `FB_EventLogCsv_Test`, `FB_F_AlarmCode_Test` и ещё 21; Библиотека plc-process-lib: `FB_Alarm_Test`, `FB_AnalogInput`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve`, `FB_ControlValve_Test`, `FB_DeviceBase_Test`, `FB_DigitalInput` и ещё 17 | `coUnit.FB_TestSuite` ×43, `FB_DeviceBase` ×7, `FB_TestDevice` ×2, `FB_Motor`, `FB_ProbeHookBase` |
| Вызов базовой реализации (`SUPER^`) | вхожд. | 6 / 3 | — | высокий | [F23](#ref-f23), [R15](#ref-r15), [C1](#ref-c1) | Вместе с `EXTENDS`; при композиции — явный вызов вложенного экземпляра | `FB_ControlValve`, `FB_Motor`, `FB_MotorVfd`, `FB_PID`, `FB_TestDevice`, `FB_TestDeviceExt`, `FB_Valve` | `SUPER^.метод` ×7, `SUPER^(…) — тело базы` ×2 |
| `THIS^` | вхожд. | 4 / 1 | — | средний | [F23](#ref-f23), [C2](#ref-c2) | Проверить компиляцией; при отказе — обращение без `THIS^` | `FB_DeviceBase`, `FB_Motor`, `FB_MotorVfd`, `FB_ProbeHookBase` |  |
| `ABSTRACT` (ФБ, метод, свойство) | член | 1 / 0 | — | средний | [F23](#ref-f23), [R15](#ref-r15), [C2](#ref-c2) | При отказе — интерфейс вместо абстрактного ФБ | `FB_DeviceBase` | `POU` |
| Методы ФБ и программ (`METHOD`) | метод | 68 / 474 | 42 / 347 | низкий | [F19](#ref-f19), [F21](#ref-f21), [F22](#ref-f22) | Переносить как есть | Флагман kns-pump-station: `FB_AlarmSummary`, `FB_AlarmSummary_Test`, `FB_Annunciator_Test`, `FB_Ats_Test`, `FB_ControlSelector_Test`, `FB_DeviceAudit_Test`, `FB_EventLog`, `FB_EventLog_Test` и ещё 37; Библиотека plc-process-lib: `FB_Alarm`, `FB_Alarm_Test`, `FB_AnalogInput`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve`, `FB_ControlValve_Test`, `FB_Delay` и ещё 25 |  |
| Методы интерфейсов | метод | 9 / 0 | 1 / 0 | низкий | [F20](#ref-f20) | Переносить как есть | Флагман kns-pump-station: `I_StationEventSink`; Библиотека plc-process-lib: `I_Alarm`, `I_AlarmSink`, `I_AlarmSource`, `I_Device`, `I_TimeSource` |  |
| Спецификатор `PUBLIC` | член | 37 / 9 | 14 / 22 | низкий | [F21](#ref-f21) | Переносить как есть | Флагман kns-pump-station: `FB_FakeEventSink`, `FB_FakeMotorVfd`, `FB_ScaledClock`, `FB_StationAlarms`, `FB_StationCore`, `FB_StormGenerator`, `FB_TankModel`, `FB_VfdSim`; Библиотека plc-process-lib: `FB_Alarm`, `FB_Delay`, `FB_DeviceBase`, `FB_FakeTime`, `FB_FopdtModel`, `FB_Motor`, `FB_MotorVfd`, `FB_ProbeHookBase` и ещё 4 | `метод` ×46, `свойство` ×36 |
| Метод или свойство без спецификатора (по умолчанию `PUBLIC`) | член | — | 12 / 3 | низкий | [F21](#ref-f21) | Переносить как есть | `FB_AlarmSummary`, `FB_EventLog`, `FB_TestAlarmSource`, `FB_VfdAdapter_Cond` | `метод` ×13, `свойство` ×2 |
| Спецификатор `PRIVATE` | член | 0 / 462 | 19 / 336 | средний | [F23](#ref-f23), [C3](#ref-c3) | Проверить компиляцией; при отказе — убрать спецификатор (доступ станет `PUBLIC`, поведение то же) | Флагман kns-pump-station: `FB_AlarmSummary`, `FB_AlarmSummary_Test`, `FB_Annunciator_Test`, `FB_Ats_Test`, `FB_ControlSelector_Test`, `FB_DeviceAudit_Test`, `FB_EventLog`, `FB_EventLog_Test` и ещё 29; Библиотека plc-process-lib: `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve_Test`, `FB_DeviceBase_Test`, `FB_DigitalInput_Test`, `FB_Integration_Test`, `FB_Motor_Test` и ещё 6 | `метод` ×817 |
| Спецификатор `PROTECTED` | член | 50 / 5 | — | средний | [F23](#ref-f23), [C3](#ref-c3) | Как `PRIVATE`; зависит от `EXTENDS` | `FB_Alarm`, `FB_AnalogInput`, `FB_ControlValve`, `FB_DeviceBase`, `FB_DigitalInput`, `FB_Motor`, `FB_MotorVfd`, `FB_PID` и ещё 5 | `метод` ×55 |
| Свойства ФБ (`PROPERTY`) | свойство | 19 / 2 | 3 / 14 | средний | [F22](#ref-f22), [C3](#ref-c3) | У вендора свойства показаны только у библиотечных ФБ; проверить в пользовательском ФБ (C3), при отказе — методы `GetX`/`SetX` | Флагман kns-pump-station: `FB_EventLog`, `FB_FakeMotorVfd`, `FB_ScaledClock`, `FB_StationAlarms`, `FB_TestAlarmSource`; Библиотека plc-process-lib: `FB_Alarm`, `FB_DeviceBase`, `FB_Motor`, `FB_MotorVfd`, `FB_TestSink` |  |
| Аксессор `Get` | аксессор | 38 / 2 | 3 / 14 | средний | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойством | Флагман kns-pump-station: `FB_EventLog`, `FB_FakeMotorVfd`, `FB_ScaledClock`, `FB_StationAlarms`, `FB_TestAlarmSource`; Библиотека plc-process-lib: `FB_Alarm`, `FB_DeviceBase`, `FB_Motor`, `FB_MotorVfd`, `FB_TestSink`, `I_Alarm`, `I_AlarmSource`, `I_Device` и ещё 2 |  |
| Свойства интерфейсов | свойство | 19 / 0 | — | средний | [F22](#ref-f22), [C3](#ref-c3) | Вместе со свойствами ФБ | `I_Alarm`, `I_AlarmSource`, `I_Device`, `I_Motor`, `I_MotorVfd` |  |
| Переменные интерфейсного типа | перем. | 8 / 74 | 46 / 19 | средний | [F85](#ref-f85), [R8](#ref-r8), [G4](#ref-g4) | В коде — как есть; в символьную конфигурацию OPC UA не публиковать (проверить G4) | Флагман kns-pump-station: `FB_AlarmSummary`, `FB_AlarmSummary_Test`, `FB_Annunciator`, `FB_Ats`, `FB_DeviceAudit`, `FB_EventLog`, `FB_EventLog_Test`, `FB_LevelControlPid` и ещё 16; Библиотека plc-process-lib: `FB_Alarm`, `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve_Test`, `FB_Delay`, `FB_DeviceBase`, `FB_DeviceBase_Test` и ещё 10 | `I_Alarm` ×55, `PL.I_Alarm` ×21, `PL.I_TimeSource` ×20, `I_TimeSource` ×12, `I_StationEventSink` ×8, `I_Device` ×6 и ещё 7 |

Не используются: `FINAL`; Спецификатор `INTERNAL`; Аксессор `Set`; Конструктор `FB_init`; `FB_exit`, `FB_reinit`; `__QUERYINTERFACE`, `__QUERYPOINTER`.

## Прагмы и атрибуты

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| `{attribute 'linkalways'}` | вхожд. | 0 / 7 | 0 / 3 | средний | [C14](#ref-c14) | В документации РегЛаб нет; проверить, что GVL без ссылок из кода попадает в приложение (C14) | Флагман kns-pump-station: `GVL_TestsInfra`, `GVL_TestsModel`, `GVL_TestsStation`; Библиотека plc-process-lib: `GVL_TestsAiDi`, `GVL_TestsAlarm`, `GVL_TestsFoundation`, `GVL_TestsIntegration`, `GVL_TestsMotor`, `GVL_TestsPid`, `GVL_TestsValve` |  |
| `{attribute 'qualified_only'}` | вхожд. | 52 / 14 | 39 / 3 | низкий | [F25](#ref-f25) | Есть | Флагман kns-pump-station: `E_ControlAct`, `E_ControlMethod`, `E_EventKind`, `E_LogExportState`, `E_PumpRole`, `E_RotationMode`, `E_SimAiFault`, `E_SimFloatStuck` и ещё 34; Библиотека plc-process-lib: `E_AiAlarm`, `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult` и ещё 58 |  |
| `{attribute 'strict'}` | вхожд. | 18 / 0 | 9 / 0 | средний | [F29](#ref-f29), [R16](#ref-r16), [C5](#ref-c5) | Проверить, что неквалифицированное обращение даёт ошибку; иначе следить вручную | Флагман kns-pump-station: `E_ControlAct`, `E_ControlMethod`, `E_EventKind`, `E_LogExportState`, `E_PumpRole`, `E_RotationMode`, `E_SimAiFault`, `E_SimFloatStuck` и ещё 1; Библиотека plc-process-lib: `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult`, `E_CvFaultAction` и ещё 10 |  |

Не используются: Условная компиляция `{IF …}`; Прагмы сообщений `{warning}`, `{error}`, `{info}`; Прочие прагмы.

## Библиотеки и пространства имён

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| Standard (таймеры, триггеры, счётчики, строки) | вхожд. | — | 46 / 1 | низкий | [F50](#ref-f50) | Переносить как есть | `F_AlarmCode`, `F_EventCsvLine`, `F_UtcToIso`, `F_ZeroPad`, `FB_EventLogCsv`, `FB_EventLogCsv_Test` | `CONCAT` ×42, `LEN` ×5 |
| SysTime, SysTimeCore, SysTimeRtc | вхожд. | — | 1 / 0 | низкий | [F52](#ref-f52), [R20](#ref-r20) | Есть; источник времени на REGUL — `FB_TimeSource_Regul` (R20) | `F_UtcNowMs` | `SysTimeRtcHighResGet` |
| CAA File (`FILE.*`) | вхожд. | — | 5 / 4 | средний | [F53](#ref-f53), [R19](#ref-r19), [C10](#ref-c10) | Проверить на ВПЛК (C10); иначе SysFile в задаче с низким приоритетом | `FB_EventLogCsv`, `FB_EventLogCsv_Test` | `FILE.MODE` ×3, `FILE.Close` ×2, `FILE.Open` ×2, `FILE.Read`, `FILE.Write` |
| coUnit (юнит-тесты: `coUnit.*`, методы `Assert*`) | вхожд. | 0 / 3902 | 0 / 2021 | высокий | [F73](#ref-f73), [R18](#ref-r18), [H2](#ref-h2), [H3](#ref-h3) | Сначала собрать тестовый проект с coUnit (H2); при отказе тесты логики — в CODESYS 3.5.17.30, на REGUL — интеграционные сценарии и PsUnittest | Флагман kns-pump-station: `FB_AlarmSummary_Test`, `FB_Annunciator_Test`, `FB_Ats_Test`, `FB_ControlSelector_Test`, `FB_DeviceAudit_Test`, `FB_EventLog_Test`, `FB_EventLogCsv_Test`, `FB_F_AlarmCode_Test` и ещё 22; Библиотека plc-process-lib: `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve_Test`, `FB_DeviceBase_Test`, `FB_DigitalInput_Test`, `FB_Integration_Test`, `FB_Motor_Test` и ещё 7 | `AssertTrue` ×1705, `coUnit.TEST` ×781, `coUnit.TEST_FINISHED` ×781, `AssertEquals_REAL` ×714, `AssertFalse` ×557, `AssertEquals_WORD` ×539 и ещё 9 |
| Своя библиотека `PL` (plc-process-lib) | вхожд. | — | 825 / 694 | низкий | [F78](#ref-f78), [F79](#ref-f79) | Переносится вместе с кодом; пространство имён `PL` не пересекается с вендорскими `Ps*` | `F_AlarmCode`, `F_FaultInjEqual`, `F_PumpCurrent`, `F_StationCfgCheck`, `FB_AlarmSummary`, `FB_AlarmSummary_Test`, `FB_AnalogSensorSim`, `FB_Annunciator` и ещё 61 | `PL.E_AlarmPriority` ×464, `PL.FB_FakeTime` ×240, `PL.E_DeviceMode` ×88, `PL.E_Ne107Status` ×73, `PL.F_IsFinite` ×62, `PL.E_AlarmState` ×59 и ещё 41 |

Не используются: Standard64 (`LTON`/`LTOF`/`LTP`, `LCTU`…, функции `WSTRING`); Util; SysFile, SysDir; CAA Memory (`MEM`), CAA SerialCom (`COM`); Библиотеки устройства (`IoStandard`, CAA Device Diagnosis `DED`); Компоненты рантайма (CmpLog, CmpApp, CmpIecTask, SysMem, SysCom, SysSocket); IECStringUtils, Base Interfaces, Breakpoint Logging.

## Типы данных

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| Тип `LTIME` | вхожд. | 37 / 19 | 24 / 24 | средний | [F30](#ref-f30), [F34](#ref-f34), [C11](#ref-c11) | Тип есть (структура OPC UA `ua_var_ltime`); арифметику проверить (C11); в OPC UA — как `ULINT` нс | Флагман kns-pump-station: `FB_AlarmSummary`, `FB_Annunciator`, `FB_PlantModel`, `FB_PumpRotation`, `FB_ScaledClock`, `FB_ScaledClock_Test`, `FB_VfdSim`, `GVL_Const`; Библиотека plc-process-lib: `F_LTimeToSec`, `FB_Alarm`, `FB_Alarm_Test`, `FB_Delay`, `FB_DeviceBase`, `FB_FakeTime`, `FB_Motor`, `FB_PID` и ещё 11 |  |
| Литералы `LTIME#`, `LT#` | вхожд. | 13 / 90 | 4 / 19 | средний | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) | Флагман kns-pump-station: `FB_AlarmSummary_Test`, `FB_Annunciator_Test`, `FB_Ats_Test`, `FB_EventLog_Test`, `FB_LevelControlPid_Test`, `FB_LevelControlStepped_Test`, `FB_PlantModel`, `FB_PlantModel_Test` и ещё 10; Библиотека plc-process-lib: `FB_Alarm_Test`, `FB_AnalogInput_Test`, `FB_Common_Test`, `FB_ControlValve_Test`, `FB_DeviceBase`, `FB_DeviceBase_Test`, `FB_FakeTime`, `FB_Motor` и ещё 9 |  |
| Преобразования `*_TO_LTIME`, `LTIME_TO_*` | вхожд. | 19 / 0 | 11 / 4 | средний | [F34](#ref-f34), [C11](#ref-c11) | Проверить компиляцией (C11) | Флагман kns-pump-station: `FB_AlarmSummary`, `FB_Annunciator`, `FB_PlantModel`, `FB_PlantModel_Test`, `FB_PumpRotation`, `FB_ScaledClock`, `FB_ScaledClock_Test`; Библиотека plc-process-lib: `F_LTimeToSec`, `FB_Alarm`, `FB_Delay`, `FB_FakeTime`, `FB_Motor`, `FB_PID` | `TIME_TO_LTIME` ×15, `LTIME_TO_ULINT` ×14, `LTIME_TO_TIME` ×3, `ULINT_TO_LTIME` ×2 |
| `LINT`, `ULINT`, `LWORD` | вхожд. | 2 / 0 | 10 / 0 | низкий | [F30](#ref-f30) | Переносить как есть | Флагман kns-pump-station: `F_UtcNowMs`, `F_UtcToIso`, `FB_AlarmSummary`, `FB_Annunciator`, `FB_EventLog`, `GVL_Const`, `ST_AlarmViewRow`, `ST_EventRecord`; Библиотека plc-process-lib: `FB_Motor` | `ULINT` ×12 |
| `POINTER TO` | вхожд. | — | 1 / 6 | средний | [F31](#ref-f31), [F85](#ref-f85), [F28](#ref-f28), [R8](#ref-r8) | Как `REFERENCE TO` | `FB_ControlSelector_Test`, `FB_EventLogCsv`, `FB_EventLogCsv_Test`, `FB_F_StationCfgCheck_Test`, `FB_StationMode_Test` |  |
| Структуры (`STRUCT`) | DUT | 25 / 3 | 16 / 0 | низкий | [F32](#ref-f32) | Переносить как есть | Флагман kns-pump-station: `ST_AlarmView`, `ST_AlarmViewRow`, `ST_EventFeed`, `ST_EventRecord`, `ST_EventView`, `ST_FaultInjection`, `ST_PlantIo`, `ST_PumpModelCfg` и ещё 8; Библиотека plc-process-lib: `ST_AiLimitCfg`, `ST_AlarmCfg`, `ST_AlarmEvent`, `ST_AnalogInputCfg`, `ST_AnalogInputCmd`, `ST_AnalogInputSts`, `ST_ControlValveCfg`, `ST_ControlValveCmd` и ещё 20 |  |
| Объединения (`UNION`) | DUT | 1 / 4 | — | низкий | [F32](#ref-f32), [C8](#ref-c8) | Есть; `UNION` в составе структуры проверить (C8) | `U_AiDiTestEnum`, `U_RealBits`, `U_TestEnumInt`, `U_TestPidEnumInt`, `U_TestValveEnum` |  |
| Перечисления | DUT | 24 / 0 | 11 / 0 | низкий | [F33](#ref-f33) | Переносить как есть | Флагман kns-pump-station: `E_ControlAct`, `E_ControlMethod`, `E_EventKind`, `E_LogExportState`, `E_PumpRole`, `E_RotationMode`, `E_SimAiFault`, `E_SimFloatStuck` и ещё 3; Библиотека plc-process-lib: `E_AiAlarm`, `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult` и ещё 16 |  |
| Перечисления с базовым типом (`(…) INT`) | DUT | 24 / 0 | 11 / 0 | средний | [F34](#ref-f34), [R17](#ref-r17), [C7](#ref-c7) | Проверить (C7); при отказе — без базового типа, с явными значениями | Флагман kns-pump-station: `E_ControlAct`, `E_ControlMethod`, `E_EventKind`, `E_LogExportState`, `E_PumpRole`, `E_RotationMode`, `E_SimAiFault`, `E_SimFloatStuck` и ещё 3; Библиотека plc-process-lib: `E_AiAlarm`, `E_AiFailValue`, `E_AiInputType`, `E_AiSignalState`, `E_AlarmEventReason`, `E_AlarmPriority`, `E_AlarmState`, `E_CmdResult` и ещё 16 | `INT` ×27, `UINT` ×8 |

Не используются: `WSTRING` и литералы `"…"`; `LDATE`, `LTOD`, `LDT`; `REFERENCE TO`; Наследование структур (`STRUCT … EXTENDS`); Псевдонимы типов; Поддиапазоны (`INT(0..100)`); Массивы переменной длины `ARRAY[*]`; Обобщённые типы `ANY`, `ANY_*`; Тип `BIT`; `__XINT`, `__UXINT`, `__XWORD`.

## Конструкции языка

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| `VAR_IN_OUT` | секция | 13 / 10 | 9 / 8 | низкий | [C13](#ref-c13) | Базовый МЭК; с массивами и строками проверить (C13) | Флагман kns-pump-station: `FB_AlarmSummary`, `FB_EventLog`, `FB_EventLogCsv`, `FB_EventLogCsv_Test`, `FB_LevelControlPid_Test`, `FB_LevelControlStepped_Test`, `FB_PlantModel`, `FB_PowerRestore_Test` и ещё 7; Библиотека plc-process-lib: `FB_AnalogInput`, `FB_AnalogInput_Test`, `FB_ControlValve`, `FB_DeviceBase`, `FB_DeviceBase_Test`, `FB_DigitalInput`, `FB_DigitalInput_Test`, `FB_Integration_Test` и ещё 7 |  |
| `VAR_IN_OUT CONSTANT` | секция | 16 / 8 | 15 / 0 | средний | [C13](#ref-c13) | Проверить (C13); при отказе — `VAR_IN_OUT` без `CONSTANT` | Флагман kns-pump-station: `F_FaultInjEqual`, `F_StationCfgCheck`, `FB_Ats`, `FB_EventLog`, `FB_InflowProfile`, `FB_LevelControlPid`, `FB_LevelControlStepped`, `FB_PlantModel` и ещё 7; Библиотека plc-process-lib: `FB_AnalogInput`, `FB_ControlValve`, `FB_DeviceBase`, `FB_DigitalInput`, `FB_Integration_Test`, `FB_Motor`, `FB_Motor_Test`, `FB_MotorVfd` и ещё 7 |  |
| `VAR_INST` | секция | — | 0 / 39 | средний | — | В исследовании нет: проверить компиляцией | `FB_AlarmSummary_Test`, `FB_DeviceAudit_Test`, `FB_EventLog_Test`, `FB_EventLogCsv_Test`, `FB_PlcStartAdoption_Test`, `FB_StationCore_Test` |  |
| `VAR_TEMP` | секция | 9 / 1 | 11 / 0 | нет | — | Базовый МЭК | Флагман kns-pump-station: `FB_Annunciator`, `FB_Ats`, `FB_LevelControlPid`, `FB_LevelControlStepped`, `FB_PowerRestore`, `FB_Protections`, `FB_PumpProtection`, `FB_PumpRotation` и ещё 3; Библиотека plc-process-lib: `FB_Alarm`, `FB_AnalogInput`, `FB_ControlValve`, `FB_Delay`, `FB_DigitalInput`, `FB_LimitMonitor`, `FB_Motor`, `FB_PID` и ещё 2 |  |
| Локальные константы (`VAR CONSTANT`) | секция | 0 / 4 | 4 / 13 | нет | — | Базовый МЭК | Флагман kns-pump-station: `F_AlarmCode`, `F_EventCsvLine`, `F_UtcToIso`, `FB_DeviceAudit_Test`, `FB_EventLog_Test`, `FB_EventLogCsv`, `FB_EventLogCsv_Test`, `FB_FakeEventSink` и ещё 9; Библиотека plc-process-lib: `FB_FopdtModel`, `FB_Runtime_Test`, `FB_TestDevice`, `FB_TestSink` |  |
| `VAR_GLOBAL CONSTANT` | секция | 8 / 0 | 5 / 0 | низкий | [F47](#ref-f47) | Переносить как есть | Флагман kns-pump-station: `GVL_CfgProject`, `GVL_Const`, `GVL_DeviceList`, `GVL_DevIdx`, `GVL_StationDefaults`; Библиотека plc-process-lib: `GVL_Const` |  |
| GVL с `VAR_GLOBAL` и `VAR_GLOBAL CONSTANT` в одном объекте | GVL | — | 1 / 0 | средний | [F47](#ref-f47) | Для экспорта PLCopenXML держать в разных списках | `GVL_DeviceList` |  |
| Оператор `LTIME()` (монотонное время) | вхожд. | 1 / 0 | 3 / 12 | средний | [F52](#ref-f52), [R20](#ref-r20), [C11](#ref-c11) | Проверить на REGUL; запасной путь — `FB_TimeSource_Regul` на `PsTimeGetUtcTimeNs` или `SysTimeRtc` | Флагман kns-pump-station: `FB_ScaledClock`, `FB_ScaledClock_Test`; Библиотека plc-process-lib: `FB_SystemTime` |  |
| `SIZEOF` | вхожд. | 0 / 31 | 0 / 7 | низкий | [§2.9](#ref-29) | Есть в примерах вендора (`ModbusUserRequest2`) | Флагман kns-pump-station: `FB_EventLog_Test`, `FB_EventLogCsv_Test`, `FB_StationCore_Test`; Библиотека plc-process-lib: `FB_Common_Test`, `FB_DeviceBase_Test`, `FB_Util_Test` |  |
| `ADR` | вхожд. | — | 2 / 8 | низкий | [F31](#ref-f31), [§2.9](#ref-29) | Есть в примерах вендора | `FB_ControlSelector_Test`, `FB_EventLogCsv`, `FB_EventLogCsv_Test`, `FB_F_StationCfgCheck_Test`, `FB_StationMode_Test` |  |
| Разыменование `^` | вхожд. | — | 1 / 7 | низкий | [F31](#ref-f31) | Есть; указатели не публиковать в OPC UA | `FB_ControlSelector_Test`, `FB_EventLogCsv`, `FB_EventLogCsv_Test`, `FB_F_StationCfgCheck_Test`, `FB_StationMode_Test` |  |

Не используются: `VAR_STAT`; `VAR_EXTERNAL`; Оператор `TIME()`; `BITADR`; Присваивание ссылки `REF=`; `__NEW`, `__DELETE`; `__ISVALIDREF`; `__TRY` … `__ENDTRY`; `__SYSTEM.*`; Прочие операторы `__*`; POU неявных проверок (`CheckBounds`, `CheckDivInt`…).

## RETAIN и PERSISTENT

| Возможность | Ед. | Библиотека plc-process-lib: src / tests | Флагман kns-pump-station: src / tests | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |
|---|---|---|---|---|---|---|---|---|
| `PERSISTENT` | перем. | — | 39 / 0 | низкий | [F38](#ref-f38), [F40](#ref-f40), [F41](#ref-f41), [R10](#ref-r10) | Есть; запись синхронизируется при каждом изменении — писать по событию или с периодом | `GVL_Persist` | `stAT401Cfg`, `stAT402Cfg`, `stES301Cfg`, `stFT202Cfg`, `stHS501Cfg`, `stHS502Cfg` и ещё 33 |
| Объект Persistent Variables (`*.pvl.st`) | объект | — | 1 / 0 | средний | [F41](#ref-f41), [R11](#ref-r11), [D1](#ref-d1) | Создать «Persistent-переменные…» вручную или импортом PLCopenXML | `GVL_Persist` |  |

Не используются: `RETAIN`; `NON_RETAIN`.

## Привязка к вводу-выводу

В коде не найдено.

Не используются: `AT %I*` / `%Q*` (адрес назначается в дереве устройств); `AT` с фиксированным адресом (`%IX0.0`, `%QW2`); `AT %M…`; Прямые адреса в коде.

## Задачи

Риск: средний ([F04](#ref-f04), [R13](#ref-r13), [J1](#ref-j1)). Переназначить приоритеты: на REGUL пользовательские 2–15 (ЦП I/III) или 5–15 (ЦП II).

| Источник | Режим | Задача | Интервал, мс | Приоритет | POU | Замечание для REGUL |
|---|---|---|---|---|---|---|
| Библиотека plc-process-lib | `normal` | `MainTask` | 20 | — | `PRG_Main` | приоритет в config.json не задан (CODESYS ставит своё значение по умолчанию); на REGUL задать явно: 2–15 на ЦП I/III типа, 5–15 на ЦП II типа |
| Библиотека plc-process-lib | `test` | `TestTask` | 10 | — | `PRG_Tests` | приоритет в config.json не задан (CODESYS ставит своё значение по умолчанию); на REGUL задать явно: 2–15 на ЦП I/III типа, 5–15 на ЦП II типа |
| Флагман kns-pump-station | `normal` | `MainTask` | 20 | 1 | `PRG_FieldIn`, `PRG_DeviceList`, `PRG_Station`, `PRG_Devices`, `PRG_FieldOut` | приоритет 1: на REGUL 0 и 1 зарезервированы — переназначить |
| Флагман kns-pump-station | `normal` | `PlantModelTask` | 20 | 2 | `PRG_PlantModel` | приоритет 2: допустим на ЦП I/III типа, на ЦП II типа — от 5 |
| Флагман kns-pump-station | `normal` | `SlowTask` | 200 | 20 | `PRG_Slow` | приоритет 20: на REGUL максимум 15 — переназначить |
| Флагман kns-pump-station | `test` | `TestTask` | 10 | 1 | `PRG_Tests` | приоритет 1: на REGUL 0 и 1 зарезервированы — переназначить |

Ссылки на библиотеки в `tools/codesys/config.json`:

| Источник | Ключ | Библиотека | Версия | Пространство имён | Режимы | Риск | Ссылки |
|---|---|---|---|---|---|---|---|
| Библиотека plc-process-lib | `counit` | coUnit (CfUnit) 1.2.0.0 | 1.2.0.0 | `coUnit` | `test` | высокий | [F73](#ref-f73), [R18](#ref-r18), [H2](#ref-h2), [H3](#ref-h3) |
| Библиотека plc-process-lib | `standard` | Standard (плейсхолдер #Standard, версию задаёт профиль CODESYS) | * | `Standard` | `normal`, `test` | низкий | [F50](#ref-f50) |
| Флагман kns-pump-station | `caa_file` | CAA File (выгрузка журнала в CSV; зонд Z1 архитектуры) | * | `FILE` | `normal`, `test` | средний | [F53](#ref-f53), [R19](#ref-r19), [C10](#ref-c10) |
| Флагман kns-pump-station | `counit` | coUnit (CfUnit) 1.2.0.0 | 1.2.0.0 | `coUnit` | `test` | высокий | [F73](#ref-f73), [R18](#ref-r18), [H2](#ref-h2), [H3](#ref-h3) |
| Флагман kns-pump-station | `plc-process-lib` | plc-process-lib 1.0.0.0 (библиотека портфолио, пространство имён PL) | 1.0.0.0 | `PL` | `normal`, `test` | низкий | [F78](#ref-f78), [F79](#ref-f79) |
| Флагман kns-pump-station | `standard` | Standard (плейсхолдер #Standard, версию задаёт профиль CODESYS) | * | `Standard` | `normal`, `test` | низкий | [F50](#ref-f50) |
| Флагман kns-pump-station | `systimertc` | SysTimeRtc (метки UTC журнала: SysTimeRtcHighResGet; как в проекте 06) | * | `SysTimeRtc` | `normal`, `test` | низкий | [F52](#ref-f52), [R20](#ref-r20) |

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
| `{attribute 'linkalways'}` | средний | 10 | [C14](#ref-c14) | В документации РегЛаб нет; проверить, что GVL без ссылок из кода попадает в приложение (C14) |
| `VAR_IN_OUT` | низкий | 40 | [C13](#ref-c13) | Базовый МЭК; с массивами и строками проверить (C13) |
| `VAR_IN_OUT CONSTANT` | средний | 39 | [C13](#ref-c13) | Проверить (C13); при отказе — `VAR_IN_OUT` без `CONSTANT` |
| `VAR_INST` | средний | 39 | добавить пункт | В исследовании нет: проверить компиляцией |

## Где именно

Файлы и строки по каждой возможности (не больше 25 файлов; остальное — в `docs/inventory.json`).

<details><summary>Интерфейсы (<code>INTERFACE</code>) — 8</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Alarm/I_Alarm.itf.st` (I_Alarm): 6
- `src/Interfaces/I_AlarmSink/I_AlarmSink.itf.st` (I_AlarmSink): 6
- `src/Interfaces/I_AlarmSource/I_AlarmSource.itf.st` (I_AlarmSource): 6
- `src/Interfaces/I_Device/I_Device.itf.st` (I_Device): 7
- `src/Interfaces/I_Motor/I_Motor.itf.st` (I_Motor): 6
- `src/Interfaces/I_MotorVfd/I_MotorVfd.itf.st` (I_MotorVfd): 6
- `src/Interfaces/I_TimeSource/I_TimeSource.itf.st` (I_TimeSource): 6

Флагман kns-pump-station:

- `src/Interfaces/I_StationEventSink/I_StationEventSink.itf.st` (I_StationEventSink): 6

</details>

<details><summary>Наследование интерфейсов (<code>INTERFACE … EXTENDS</code>) — 3</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Device/I_Device.itf.st` (I_Device): 7
- `src/Interfaces/I_Motor/I_Motor.itf.st` (I_Motor): 6
- `src/Interfaces/I_MotorVfd/I_MotorVfd.itf.st` (I_MotorVfd): 6

</details>

<details><summary>Реализация интерфейсов (<code>IMPLEMENTS</code>) — 13</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/FB_Alarm.decl.st` (FB_Alarm): 11
- `src/POUs/Base/FB_DeviceBase/FB_DeviceBase.decl.st` (FB_DeviceBase): 11
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 13
- `src/POUs/Devices/FB_MotorVfd/FB_MotorVfd.decl.st` (FB_MotorVfd): 10
- `src/POUs/Time/FB_FakeTime/FB_FakeTime.decl.st` (FB_FakeTime): 9
- `src/POUs/Time/FB_SystemTime/FB_SystemTime.decl.st` (FB_SystemTime): 9
- `tests/POUs/Helpers/FB_TestSink/FB_TestSink.decl.st` (FB_TestSink): 7

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLog/FB_EventLog.decl.st` (FB_EventLog): 11
- `src/POUs/Station/FB_StationAlarms/FB_StationAlarms.decl.st` (FB_StationAlarms): 8
- `src/POUs/Time/FB_ScaledClock/FB_ScaledClock.decl.st` (FB_ScaledClock): 9
- `tests/POUs/Fakes/FB_FakeEventSink/FB_FakeEventSink.decl.st` (FB_FakeEventSink): 6
- `tests/POUs/Fakes/FB_FakeMotorVfd/FB_FakeMotorVfd.decl.st` (FB_FakeMotorVfd): 9
- `tests/POUs/Log/FB_TestAlarmSource/FB_TestAlarmSource.decl.st` (FB_TestAlarmSource): 6

</details>

<details><summary>Наследование ФБ (<code>FUNCTION_BLOCK … EXTENDS</code>) — 54</summary>

Флагман kns-pump-station:

- `tests/POUs/Field/FB_PlcStartAdoption_Test/FB_PlcStartAdoption_Test.decl.st` (FB_PlcStartAdoption_Test): 10
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/FB_VfdAdapter_Cond_Test.decl.st` (FB_VfdAdapter_Cond_Test): 7
- `tests/POUs/Log/FB_AlarmSummary_Test/FB_AlarmSummary_Test.decl.st` (FB_AlarmSummary_Test): 8
- `tests/POUs/Log/FB_DeviceAudit_Test/FB_DeviceAudit_Test.decl.st` (FB_DeviceAudit_Test): 7
- `tests/POUs/Log/FB_EventLogCsv_Test/FB_EventLogCsv_Test.decl.st` (FB_EventLogCsv_Test): 8
- `tests/POUs/Log/FB_EventLog_Test/FB_EventLog_Test.decl.st` (FB_EventLog_Test): 9
- `tests/POUs/Log/FB_F_AlarmCode_Test/FB_F_AlarmCode_Test.decl.st` (FB_F_AlarmCode_Test): 7
- `tests/POUs/Log/FB_F_UtcToIso_Test/FB_F_UtcToIso_Test.decl.st` (FB_F_UtcToIso_Test): 7
- `tests/POUs/Model/FB_HydraulicSolver_Test/FB_HydraulicSolver_Test.decl.st` (FB_HydraulicSolver_Test): 9
- `tests/POUs/Model/FB_InflowProfile_Test/FB_InflowProfile_Test.decl.st` (FB_InflowProfile_Test): 7
- `tests/POUs/Model/FB_PlantModel_Test/FB_PlantModel_Test.decl.st` (FB_PlantModel_Test): 10
- `tests/POUs/Model/FB_ScaledClock_Test/FB_ScaledClock_Test.decl.st` (FB_ScaledClock_Test): 8
- `tests/POUs/Model/FB_StormGenerator_Test/FB_StormGenerator_Test.decl.st` (FB_StormGenerator_Test): 8
- `tests/POUs/Model/FB_TankModel_Test/FB_TankModel_Test.decl.st` (FB_TankModel_Test): 7
- `tests/POUs/Model/FB_VfdSim_Test/FB_VfdSim_Test.decl.st` (FB_VfdSim_Test): 10
- `tests/POUs/Station/FB_Annunciator_Test/FB_Annunciator_Test.decl.st` (FB_Annunciator_Test): 7
- `tests/POUs/Station/FB_Ats_Test/FB_Ats_Test.decl.st` (FB_Ats_Test): 7
- `tests/POUs/Station/FB_ControlSelector_Test/FB_ControlSelector_Test.decl.st` (FB_ControlSelector_Test): 7
- `tests/POUs/Station/FB_F_StationCfgCheck_Test/FB_F_StationCfgCheck_Test.decl.st` (FB_F_StationCfgCheck_Test): 6
- `tests/POUs/Station/FB_LevelControlPid_Test/FB_LevelControlPid_Test.decl.st` (FB_LevelControlPid_Test): 8
- `tests/POUs/Station/FB_LevelControlStepped_Test/FB_LevelControlStepped_Test.decl.st` (FB_LevelControlStepped_Test): 7
- `tests/POUs/Station/FB_PowerRestore_Test/FB_PowerRestore_Test.decl.st` (FB_PowerRestore_Test): 7
- `tests/POUs/Station/FB_Protections_Test/FB_Protections_Test.decl.st` (FB_Protections_Test): 8
- `tests/POUs/Station/FB_PumpProtection_Test/FB_PumpProtection_Test.decl.st` (FB_PumpProtection_Test): 7
- `tests/POUs/Station/FB_PumpRotation_Test/FB_PumpRotation_Test.decl.st` (FB_PumpRotation_Test): 8

… и ещё 29 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Вызов базовой реализации (<code>SUPER^</code>) — 9</summary>

Библиотека plc-process-lib:

- `src/POUs/Control/FB_PID/OnModeChanged.method.impl.st` (FB_PID): 1
- `src/POUs/Devices/FB_ControlValve/OnModeChanged.method.impl.st` (FB_ControlValve): 1
- `src/POUs/Devices/FB_Motor/OnModeChanged.method.impl.st` (FB_Motor): 1
- `src/POUs/Devices/FB_MotorVfd/CheckConfig.method.impl.st` (FB_MotorVfd): 1
- `src/POUs/Devices/FB_MotorVfd/FB_MotorVfd.impl.st` (FB_MotorVfd): 66
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

<details><summary>Методы ФБ и программ (<code>METHOD</code>) — 931</summary>

Флагман kns-pump-station:

- `src/POUs/Field/FB_VfdAdapter_Cond/Decode.method.decl.st` (FB_VfdAdapter_Cond): 2
- `src/POUs/Field/FB_VfdAdapter_Cond/Encode.method.decl.st` (FB_VfdAdapter_Cond): 4
- `src/POUs/Log/FB_AlarmSummary/AckById.method.decl.st` (FB_AlarmSummary): 3
- `src/POUs/Log/FB_AlarmSummary/BuildView.method.decl.st` (FB_AlarmSummary): 3
- `src/POUs/Log/FB_AlarmSummary/FindAlarm.method.decl.st` (FB_AlarmSummary): 2
- `src/POUs/Log/FB_AlarmSummary/ShelveById.method.decl.st` (FB_AlarmSummary): 3
- `src/POUs/Log/FB_EventLog/FillFeed.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLog/FillView.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLog/GetRecord.method.decl.st` (FB_EventLog): 2
- `src/POUs/Log/FB_EventLog/GetSnapshotRecord.method.decl.st` (FB_EventLog): 2
- `src/POUs/Log/FB_EventLog/LogEvent.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLog/OnAlarmEvent.method.decl.st` (FB_EventLog): 2
- `src/POUs/Log/FB_EventLog/Store.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLog/TakeSnapshot.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLogCsv/AppendText.method.decl.st` (FB_EventLogCsv): 2
- `src/POUs/Model/FB_HydraulicSolver/FlowsAt.method.decl.st` (FB_HydraulicSolver): 3
- `src/POUs/Model/FB_HydraulicSolver/Solve.method.decl.st` (FB_HydraulicSolver): 4
- `src/POUs/Model/FB_PlantModel/DayOf.method.decl.st` (FB_PlantModel): 2
- `src/POUs/Model/FB_PlantModel/TodOf.method.decl.st` (FB_PlantModel): 2
- `src/POUs/Model/FB_StormGenerator/AddStorm.method.decl.st` (FB_StormGenerator): 3
- `src/POUs/Model/FB_StormGenerator/Clear.method.decl.st` (FB_StormGenerator): 3
- `src/POUs/Model/FB_StormGenerator/Draw.method.decl.st` (FB_StormGenerator): 2
- `src/POUs/Model/FB_StormGenerator/FloorU.method.decl.st` (FB_StormGenerator): 2
- `src/POUs/Model/FB_StormGenerator/Generate.method.decl.st` (FB_StormGenerator): 3
- `src/POUs/Model/FB_StormGenerator/StartNow.method.decl.st` (FB_StormGenerator): 3

… и ещё 906 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Методы интерфейсов — 10</summary>

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

Флагман kns-pump-station:

- `src/Interfaces/I_StationEventSink/LogEvent.method.decl.st` (I_StationEventSink): 2

</details>

<details><summary>Спецификатор <code>PUBLIC</code> — 82</summary>

Флагман kns-pump-station:

- `src/POUs/Model/FB_StormGenerator/Clear.method.decl.st` (FB_StormGenerator): 3
- `src/POUs/Model/FB_StormGenerator/StartNow.method.decl.st` (FB_StormGenerator): 3
- `src/POUs/Model/FB_TankModel/ClearOverflow.method.decl.st` (FB_TankModel): 3
- `src/POUs/Model/FB_TankModel/SetLevel.method.decl.st` (FB_TankModel): 4
- `src/POUs/Model/FB_VfdSim/ResetDrive.method.decl.st` (FB_VfdSim): 4
- `src/POUs/Station/FB_StationAlarms/AckAll.method.decl.st` (FB_StationAlarms): 2
- `src/POUs/Station/FB_StationAlarms/AlarmCount.prop.decl.st` (FB_StationAlarms): 2
- `src/POUs/Station/FB_StationAlarms/GetAlarm.method.decl.st` (FB_StationAlarms): 2
- `src/POUs/Station/FB_StationCore/ChangedParam.method.decl.st` (FB_StationCore): 5
- `src/POUs/Time/FB_ScaledClock/AdvanceL.method.decl.st` (FB_ScaledClock): 2
- `src/POUs/Time/FB_ScaledClock/Now.method.decl.st` (FB_ScaledClock): 2
- `src/POUs/Time/FB_ScaledClock/Scale.prop.decl.st` (FB_ScaledClock): 2
- `src/POUs/Time/FB_ScaledClock/SetManual.method.decl.st` (FB_ScaledClock): 4
- `src/POUs/Time/FB_ScaledClock/Update.method.decl.st` (FB_ScaledClock): 3
- `tests/POUs/Fakes/FB_FakeEventSink/Clear.method.decl.st` (FB_FakeEventSink): 2
- `tests/POUs/Fakes/FB_FakeEventSink/CountOf.method.decl.st` (FB_FakeEventSink): 2
- `tests/POUs/Fakes/FB_FakeEventSink/Has.method.decl.st` (FB_FakeEventSink): 2
- `tests/POUs/Fakes/FB_FakeEventSink/LogEvent.method.decl.st` (FB_FakeEventSink): 2
- `tests/POUs/Fakes/FB_FakeEventSink/ValueOf.method.decl.st` (FB_FakeEventSink): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/AckAll.method.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/AlarmCount.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Available.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/CurrentRunSeconds.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Fault.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/GetAlarm.method.decl.st` (FB_FakeMotorVfd): 2

… и ещё 57 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Метод или свойство без спецификатора (по умолчанию <code>PUBLIC</code>) — 15</summary>

Флагман kns-pump-station:

- `src/POUs/Field/FB_VfdAdapter_Cond/Decode.method.decl.st` (FB_VfdAdapter_Cond): 2
- `src/POUs/Field/FB_VfdAdapter_Cond/Encode.method.decl.st` (FB_VfdAdapter_Cond): 4
- `src/POUs/Log/FB_AlarmSummary/AckById.method.decl.st` (FB_AlarmSummary): 3
- `src/POUs/Log/FB_AlarmSummary/ShelveById.method.decl.st` (FB_AlarmSummary): 3
- `src/POUs/Log/FB_EventLog/FillFeed.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLog/FillView.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLog/GetRecord.method.decl.st` (FB_EventLog): 2
- `src/POUs/Log/FB_EventLog/GetSnapshotRecord.method.decl.st` (FB_EventLog): 2
- `src/POUs/Log/FB_EventLog/LogEvent.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLog/OnAlarmEvent.method.decl.st` (FB_EventLog): 2
- `src/POUs/Log/FB_EventLog/SnapshotCount.prop.decl.st` (FB_EventLog): 2
- `src/POUs/Log/FB_EventLog/TakeSnapshot.method.decl.st` (FB_EventLog): 3
- `tests/POUs/Log/FB_TestAlarmSource/AckAll.method.decl.st` (FB_TestAlarmSource): 2
- `tests/POUs/Log/FB_TestAlarmSource/AlarmCount.prop.decl.st` (FB_TestAlarmSource): 2
- `tests/POUs/Log/FB_TestAlarmSource/GetAlarm.method.decl.st` (FB_TestAlarmSource): 2

</details>

<details><summary>Спецификатор <code>PRIVATE</code> — 817</summary>

Флагман kns-pump-station:

- `src/POUs/Log/FB_AlarmSummary/BuildView.method.decl.st` (FB_AlarmSummary): 3
- `src/POUs/Log/FB_AlarmSummary/FindAlarm.method.decl.st` (FB_AlarmSummary): 2
- `src/POUs/Log/FB_EventLog/Store.method.decl.st` (FB_EventLog): 3
- `src/POUs/Log/FB_EventLogCsv/AppendText.method.decl.st` (FB_EventLogCsv): 2
- `src/POUs/Model/FB_HydraulicSolver/FlowsAt.method.decl.st` (FB_HydraulicSolver): 3
- `src/POUs/Model/FB_HydraulicSolver/Solve.method.decl.st` (FB_HydraulicSolver): 4
- `src/POUs/Model/FB_PlantModel/DayOf.method.decl.st` (FB_PlantModel): 2
- `src/POUs/Model/FB_PlantModel/TodOf.method.decl.st` (FB_PlantModel): 2
- `src/POUs/Model/FB_StormGenerator/AddStorm.method.decl.st` (FB_StormGenerator): 3
- `src/POUs/Model/FB_StormGenerator/Draw.method.decl.st` (FB_StormGenerator): 2
- `src/POUs/Model/FB_StormGenerator/FloorU.method.decl.st` (FB_StormGenerator): 2
- `src/POUs/Model/FB_StormGenerator/Generate.method.decl.st` (FB_StormGenerator): 3
- `src/POUs/Station/FB_PumpRotation/Better.method.decl.st` (FB_PumpRotation): 4
- `src/POUs/Station/FB_PumpRotation/PickCandidate.method.decl.st` (FB_PumpRotation): 6
- `src/POUs/Station/FB_PumpRotation/PickIn.method.decl.st` (FB_PumpRotation): 3
- `src/POUs/Station/FB_PumpRotation/PickLead.method.decl.st` (FB_PumpRotation): 3
- `src/POUs/Station/FB_PumpRotation/PickLeadIn.method.decl.st` (FB_PumpRotation): 4
- `src/POUs/Station/FB_PumpRotation/PickToRemove.method.decl.st` (FB_PumpRotation): 5
- `src/POUs/Time/FB_ScaledClock/ScaledAt.method.decl.st` (FB_ScaledClock): 3
- `tests/POUs/Field/FB_PlcStartAdoption_Test/AdoptedInGeneratedOrder.method.decl.st` (FB_PlcStartAdoption_Test): 4
- `tests/POUs/Field/FB_PlcStartAdoption_Test/PowerDeviceAfterPumpStopsRunningPump.method.decl.st` (FB_PlcStartAdoption_Test): 4
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/DecodeBits.method.decl.st` (FB_VfdAdapter_Cond_Test): 3
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/DecodeScale5000Is100Pct.method.decl.st` (FB_VfdAdapter_Cond_Test): 2
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/DefaultsAllFalse.method.decl.st` (FB_VfdAdapter_Cond_Test): 2
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/EncodeNanIsZero.method.decl.st` (FB_VfdAdapter_Cond_Test): 2

… и ещё 792 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Спецификатор <code>PROTECTED</code> — 55</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/ReleaseState.method.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/Transit.method.decl.st` (FB_Alarm): 5
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
- `src/POUs/Devices/FB_AnalogInput/ComputeValue.method.decl.st` (FB_AnalogInput): 9
- `src/POUs/Devices/FB_AnalogInput/FaultBits.method.decl.st` (FB_AnalogInput): 2
- `src/POUs/Devices/FB_AnalogInput/SelectValue.method.decl.st` (FB_AnalogInput): 8

… и ещё 30 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Свойства ФБ (<code>PROPERTY</code>) — 38</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/Active.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/AlarmPriority.prop.decl.st` (FB_Alarm): 3
- `src/POUs/Alarm/FB_Alarm/Id.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Seq.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/State.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Alarm/FB_Alarm/Unacked.prop.decl.st` (FB_Alarm): 2
- `src/POUs/Base/FB_DeviceBase/AlarmCount.prop.decl.st` (FB_DeviceBase): 2
- `src/POUs/Base/FB_DeviceBase/Available.prop.decl.st` (FB_DeviceBase): 2

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLog/SnapshotCount.prop.decl.st` (FB_EventLog): 2
- `src/POUs/Station/FB_StationAlarms/AlarmCount.prop.decl.st` (FB_StationAlarms): 2
- `src/POUs/Time/FB_ScaledClock/Scale.prop.decl.st` (FB_ScaledClock): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/AlarmCount.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Available.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/CurrentRunSeconds.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Fault.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Mode.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/ReadyToStart.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/RunSeconds.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Running.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/SpeedAct.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/SpeedAutoActive.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/SpeedRef.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Starts.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Fakes/FB_FakeMotorVfd/Status.prop.decl.st` (FB_FakeMotorVfd): 2
- `tests/POUs/Log/FB_TestAlarmSource/AlarmCount.prop.decl.st` (FB_TestAlarmSource): 2

… и ещё 13 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Аксессор <code>Get</code> — 57</summary>

Библиотека plc-process-lib:

- `src/Interfaces/I_Alarm/Active.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/AlarmPriority.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/Id.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/Seq.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/State.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_Alarm/Unacked.get.decl.st` (I_Alarm): 1
- `src/Interfaces/I_AlarmSource/AlarmCount.get.decl.st` (I_AlarmSource): 1
- `src/Interfaces/I_Device/Available.get.decl.st` (I_Device): 1

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLog/SnapshotCount.get.impl.st` (FB_EventLog): 1
- `src/POUs/Station/FB_StationAlarms/AlarmCount.get.impl.st` (FB_StationAlarms): 1
- `src/POUs/Time/FB_ScaledClock/Scale.get.impl.st` (FB_ScaledClock): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/AlarmCount.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/Available.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/CurrentRunSeconds.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/Fault.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/Mode.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/ReadyToStart.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/RunSeconds.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/Running.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/SpeedAct.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/SpeedAutoActive.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/SpeedRef.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/Starts.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Fakes/FB_FakeMotorVfd/Status.get.impl.st` (FB_FakeMotorVfd): 1
- `tests/POUs/Log/FB_TestAlarmSource/AlarmCount.get.impl.st` (FB_TestAlarmSource): 1

… и ещё 32 файлов — полный список в `docs/inventory.json`.

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

<details><summary>Переменные интерфейсного типа — 147</summary>

Флагман kns-pump-station:

- `src/GVLs/Generated/GVL_DeviceList.gvl.st` (GVL_DeviceList): 63
- `src/POUs/Log/FB_AlarmSummary/AckById.method.decl.st` (FB_AlarmSummary): 8
- `src/POUs/Log/FB_AlarmSummary/BuildView.method.decl.st` (FB_AlarmSummary): 19, 20
- `src/POUs/Log/FB_AlarmSummary/FB_AlarmSummary.decl.st` (FB_AlarmSummary): 12, 14, 31, 39, 40
- `src/POUs/Log/FB_AlarmSummary/FindAlarm.method.decl.st` (FB_AlarmSummary): 9, 10
- `src/POUs/Log/FB_AlarmSummary/ShelveById.method.decl.st` (FB_AlarmSummary): 9
- `src/POUs/Log/FB_DeviceAudit/FB_DeviceAudit.decl.st` (FB_DeviceAudit): 9, 11, 21
- `src/POUs/Log/FB_EventLog/FB_EventLog.decl.st` (FB_EventLog): 13
- `src/POUs/Log/FB_EventLog/Store.method.decl.st` (FB_EventLog): 15
- `src/POUs/Model/FB_PlantModel/FB_PlantModel.decl.st` (FB_PlantModel): 14, 34
- `src/POUs/Model/FB_VfdSim/FB_VfdSim.decl.st` (FB_VfdSim): 30, 49
- `src/POUs/Station/FB_Annunciator/FB_Annunciator.decl.st` (FB_Annunciator): 15
- `src/POUs/Station/FB_Ats/FB_Ats.decl.st` (FB_Ats): 14, 20, 21
- `src/POUs/Station/FB_LevelControlPid/FB_LevelControlPid.decl.st` (FB_LevelControlPid): 15, 20
- `src/POUs/Station/FB_LevelControlStepped/FB_LevelControlStepped.decl.st` (FB_LevelControlStepped): 16
- `src/POUs/Station/FB_PowerRestore/FB_PowerRestore.decl.st` (FB_PowerRestore): 16, 17
- `src/POUs/Station/FB_Protections/FB_Protections.decl.st` (FB_Protections): 23, 24
- `src/POUs/Station/FB_PumpProtection/FB_PumpProtection.decl.st` (FB_PumpProtection): 16
- `src/POUs/Station/FB_PumpRotation/FB_PumpRotation.decl.st` (FB_PumpRotation): 23, 25, 26
- `src/POUs/Station/FB_StationAlarms/FB_StationAlarms.decl.st` (FB_StationAlarms): 17
- `src/POUs/Station/FB_StationCore/FB_StationCore.decl.st` (FB_StationCore): 16, 17, 18
- `src/POUs/Station/FB_StationMode/FB_StationMode.decl.st` (FB_StationMode): 16, 17
- `src/POUs/Station/FB_Ventilation/FB_Ventilation.decl.st` (FB_Ventilation): 13
- `src/POUs/Station/PRG_Station/PRG_Station.decl.st` (PRG_Station): 9, 10, 11
- `tests/POUs/Log/FB_AlarmSummary_Test/AckByIdDeviceStationPid.method.decl.st` (FB_AlarmSummary_Test): 13

… и ещё 86 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>{attribute 'linkalways'}</code> — 10</summary>

Библиотека plc-process-lib:

- `tests/GVLs/GVL_TestsAiDi.gvl.st` (GVL_TestsAiDi): 9
- `tests/GVLs/GVL_TestsAlarm.gvl.st` (GVL_TestsAlarm): 8
- `tests/GVLs/GVL_TestsFoundation.gvl.st` (GVL_TestsFoundation): 10
- `tests/GVLs/GVL_TestsIntegration.gvl.st` (GVL_TestsIntegration): 8
- `tests/GVLs/GVL_TestsMotor.gvl.st` (GVL_TestsMotor): 8
- `tests/GVLs/GVL_TestsPid.gvl.st` (GVL_TestsPid): 8
- `tests/GVLs/GVL_TestsValve.gvl.st` (GVL_TestsValve): 10

Флагман kns-pump-station:

- `tests/GVLs/GVL_TestsInfra.gvl.st` (GVL_TestsInfra): 8
- `tests/GVLs/GVL_TestsModel.gvl.st` (GVL_TestsModel): 9
- `tests/GVLs/GVL_TestsStation.gvl.st` (GVL_TestsStation): 8

</details>

<details><summary><code>{attribute 'qualified_only'}</code> — 108</summary>

Флагман kns-pump-station:

- `src/DUTs/Log/E_EventKind.dut.st` (E_EventKind): 5
- `src/DUTs/Log/E_LogExportState.dut.st` (E_LogExportState): 5
- `src/DUTs/Log/E_StationEvent.dut.st` (E_StationEvent): 6
- `src/DUTs/Log/ST_AlarmView.dut.st` (ST_AlarmView): 6
- `src/DUTs/Log/ST_AlarmViewRow.dut.st` (ST_AlarmViewRow): 5
- `src/DUTs/Log/ST_EventFeed.dut.st` (ST_EventFeed): 8
- `src/DUTs/Log/ST_EventRecord.dut.st` (ST_EventRecord): 6
- `src/DUTs/Log/ST_EventView.dut.st` (ST_EventView): 5
- `src/DUTs/Sim/E_SimAiFault.dut.st` (E_SimAiFault): 6
- `src/DUTs/Sim/E_SimFloatStuck.dut.st` (E_SimFloatStuck): 5
- `src/DUTs/Sim/ST_FaultInjection.dut.st` (ST_FaultInjection): 7
- `src/DUTs/Sim/ST_PlantIo.dut.st` (ST_PlantIo): 8
- `src/DUTs/Sim/ST_PumpModelCfg.dut.st` (ST_PumpModelCfg): 7
- `src/DUTs/Sim/ST_SimCfg.dut.st` (ST_SimCfg): 6
- `src/DUTs/Sim/ST_SimCmd.dut.st` (ST_SimCmd): 6
- `src/DUTs/Sim/ST_SimSts.dut.st` (ST_SimSts): 6
- `src/DUTs/Sim/ST_StormEvent.dut.st` (ST_StormEvent): 6
- `src/DUTs/Station/E_ControlAct.dut.st` (E_ControlAct): 7
- `src/DUTs/Station/E_ControlMethod.dut.st` (E_ControlMethod): 6
- `src/DUTs/Station/E_PumpRole.dut.st` (E_PumpRole): 5
- `src/DUTs/Station/E_RotationMode.dut.st` (E_RotationMode): 5
- `src/DUTs/Station/E_StationAlarm.dut.st` (E_StationAlarm): 7
- `src/DUTs/Station/E_StationMode.dut.st` (E_StationMode): 6
- `src/DUTs/Station/ST_StationCfg.dut.st` (ST_StationCfg): 8
- `src/DUTs/Station/ST_StationCmd.dut.st` (ST_StationCmd): 7

… и ещё 83 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>{attribute 'strict'}</code> — 27</summary>

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

Флагман kns-pump-station:

- `src/DUTs/Log/E_EventKind.dut.st` (E_EventKind): 6
- `src/DUTs/Log/E_LogExportState.dut.st` (E_LogExportState): 6
- `src/DUTs/Sim/E_SimAiFault.dut.st` (E_SimAiFault): 7
- `src/DUTs/Sim/E_SimFloatStuck.dut.st` (E_SimFloatStuck): 6
- `src/DUTs/Station/E_ControlAct.dut.st` (E_ControlAct): 8
- `src/DUTs/Station/E_ControlMethod.dut.st` (E_ControlMethod): 7
- `src/DUTs/Station/E_PumpRole.dut.st` (E_PumpRole): 6
- `src/DUTs/Station/E_RotationMode.dut.st` (E_RotationMode): 6
- `src/DUTs/Station/E_StationMode.dut.st` (E_StationMode): 7

… и ещё 2 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Standard (таймеры, триггеры, счётчики, строки) — 47</summary>

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLogCsv/AppendText.method.impl.st` (FB_EventLogCsv): 2
- `src/POUs/Log/F_AlarmCode/F_AlarmCode.impl.st` (F_AlarmCode): 4, 5, 9, 10, 13, 37, 40
- `src/POUs/Log/F_EventCsvLine/F_EventCsvLine.impl.st` (F_EventCsvLine): 7, 8, 9, 10, 12, 13, 14, 15, 16
- `src/POUs/Log/F_UtcToIso/F_UtcToIso.impl.st` (F_UtcToIso): 24, 25, 27, 28, 31
- `src/POUs/Log/F_ZeroPad/F_ZeroPad.impl.st` (F_ZeroPad): 2, 3
- `tests/POUs/Log/FB_EventLogCsv_Test/AppendExpected.method.impl.st` (FB_EventLogCsv_Test): 2

</details>

<details><summary>SysTime, SysTimeCore, SysTimeRtc — 1</summary>

Флагман kns-pump-station:

- `src/POUs/Log/F_UtcNowMs/F_UtcNowMs.impl.st` (F_UtcNowMs): 1

</details>

<details><summary>CAA File (<code>FILE.*</code>) — 9</summary>

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLogCsv/FB_EventLogCsv.decl.st` (FB_EventLogCsv): 24, 25, 26, 42
- `tests/POUs/Log/FB_EventLogCsv_Test/ReadBackMatchesSnapshot.method.decl.st` (FB_EventLogCsv_Test): 7, 8, 9
- `tests/POUs/Log/FB_EventLogCsv_Test/ReadBackMatchesSnapshot.method.impl.st` (FB_EventLogCsv_Test): 25

</details>

<details><summary>coUnit (юнит-тесты: <code>coUnit.*</code>, методы <code>Assert*</code>) — 5923</summary>

Флагман kns-pump-station:

- `tests/POUs/Field/FB_PlcStartAdoption_Test/AdoptedInGeneratedOrder.method.impl.st` (FB_PlcStartAdoption_Test): 1, 12, 13, 14, 25, 26, 27, 28, 30
- `tests/POUs/Field/FB_PlcStartAdoption_Test/FB_PlcStartAdoption_Test.decl.st` (FB_PlcStartAdoption_Test): 10
- `tests/POUs/Field/FB_PlcStartAdoption_Test/PowerDeviceAfterPumpStopsRunningPump.method.impl.st` (FB_PlcStartAdoption_Test): 1, 12, 13, 15
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/DecodeBits.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 5, 6, 7, 8, 9, 10, 13, 14, 15, 16, 17, 19
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/DecodeScale5000Is100Pct.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 4, 6, 8, 10
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/DefaultsAllFalse.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 3, 5, 6, 7, 9
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/EncodeNanIsZero.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 4, 7, 8, 11, 13
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/EncodeResetBitWhileQReset.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 4, 6, 8
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/EncodeRoundsToNearest.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 4, 6, 8, 10
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/EncodeScaleAndClamp.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 4, 6, 8, 10, 12, 14
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/FB_VfdAdapter_Cond_Test.decl.st` (FB_VfdAdapter_Cond_Test): 7
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/NoCommForcesStatusFalseHoldsSpeed.method.impl.st` (FB_VfdAdapter_Cond_Test): 1, 6, 8, 9, 11, 13, 14, 16
- `tests/POUs/Log/FB_AlarmSummary_Test/AckByIdDeviceStationPid.method.impl.st` (FB_AlarmSummary_Test): 1, 13, 14, 15, 16, 22, 24, 26, 27, 28, 30
- `tests/POUs/Log/FB_AlarmSummary_Test/CountsByPriority.method.impl.st` (FB_AlarmSummary_Test): 1, 18, 19, 20, 21, 22, 23, 24, 26
- `tests/POUs/Log/FB_AlarmSummary_Test/EmptyDefaults.method.impl.st` (FB_AlarmSummary_Test): 1, 5, 7, 8, 9, 11
- `tests/POUs/Log/FB_AlarmSummary_Test/FB_AlarmSummary_Test.decl.st` (FB_AlarmSummary_Test): 8
- `tests/POUs/Log/FB_AlarmSummary_Test/NewHighSeqOnlyOnTransition.method.impl.st` (FB_AlarmSummary_Test): 1, 8, 13, 17, 24, 26
- `tests/POUs/Log/FB_AlarmSummary_Test/PrioUnackHighest.method.impl.st` (FB_AlarmSummary_Test): 1, 13, 17, 19
- `tests/POUs/Log/FB_AlarmSummary_Test/PrioUnackHighestBeforeLower.method.impl.st` (FB_AlarmSummary_Test): 1, 10, 12
- `tests/POUs/Log/FB_AlarmSummary_Test/ShelveByIdRespectsTShelveMax.method.impl.st` (FB_AlarmSummary_Test): 1, 11, 12, 15, 17, 21, 24
- `tests/POUs/Log/FB_AlarmSummary_Test/ShelveByIdUsesFullTShelveMax.method.impl.st` (FB_AlarmSummary_Test): 1, 7, 12, 16, 18
- `tests/POUs/Log/FB_AlarmSummary_Test/SlotMaxMatchesLibrary.method.impl.st` (FB_AlarmSummary_Test): 1, 3, 6
- `tests/POUs/Log/FB_AlarmSummary_Test/StationSlotsBeyondDeviceLimit.method.impl.st` (FB_AlarmSummary_Test): 1, 3, 12, 13, 14, 16, 17, 20, 23, 25
- `tests/POUs/Log/FB_AlarmSummary_Test/TimeBackwardsRebuildsView.method.impl.st` (FB_AlarmSummary_Test): 1, 6, 9, 11
- `tests/POUs/Log/FB_AlarmSummary_Test/UnshelveById.method.impl.st` (FB_AlarmSummary_Test): 1, 10, 11, 14, 15, 17

… и ещё 801 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Своя библиотека <code>PL</code> (plc-process-lib) — 1519</summary>

Флагман kns-pump-station:

- `src/DUTs/Log/ST_AlarmViewRow.dut.st` (ST_AlarmViewRow): 9, 10
- `src/DUTs/Log/ST_EventRecord.dut.st` (ST_EventRecord): 11, 13, 14, 15
- `src/DUTs/Station/ST_StationCfg.dut.st` (ST_StationCfg): 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65
- `src/DUTs/Station/ST_StationSts.dut.st` (ST_StationSts): 12, 22, 27
- `src/GVLs/Generated/GVL_CfgProject.gvl.st` (GVL_CfgProject): 9, 25, 41, 57, 61, 62, 63, 64, 65, 66, 67, 68, 73, 84, 85, 86, 87, 88, 89, 90, 91, 96, 101, 102, 103, 104, 105, 106, 107, 108, 113, 116, 119, 120, 121, 122, 123, 124, 125, 126, 131, 132, 144, 145, 146, 147, 148, 149, 150, 151, 156, 160, 161, 162, 163, 164, 165, 166, 167, 172, 176, 177, 178, 179, 180, 181, 182, 183, 188, 189, 201, 202, 203, 204, 205, 206, 207, 208, 213, 217, 218, 219, 220, 221, 222, 223, 224, 229, 233, 234, 235, 236, 237, 238, 239, 240, 245, 246, 258, 259, 260, 261, 262, 263, 264, 265, 270, 274, 275, 276, 277, 278, 279, 280, 281, 286, 290, 291, 292, 293, 294, 295, 296, 297, 302, 313, 314, 315, 316, 317, 318, 319, 320, 325, 337, 338, 339, 340, 341, 342, 343, 344, 349, 353, 354, 355, 356, 357, 358, 359, 360, 365, 370, 371, 372, 373, 374, 375, 376, 377, 382, 386, 387, 388, 389, 390, 391, 392, 393, 398, 402, 403, 404, 405, 406, 407, 408, 409, 414, 424, 425, 426, 427, 428, 429, 430, 431, 436, 445, 446, 447, 448, 449, 450, 451, 452, 457, 458, 469, 470, 471, 472, 473, 474, 475, 476, 481, 485, 486, 487, 488, 489, 490, 491, 492, 497, 500, 501, 502, 503, 504, 505, 506, 507, 512, 515
- `src/GVLs/Generated/GVL_DeviceList.gvl.st` (GVL_DeviceList): 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 63
- `src/GVLs/Generated/GVL_Devices.gvl.st` (GVL_Devices): 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35
- `src/GVLs/Generated/GVL_Hmi.gvl.st` (GVL_Hmi): 8, 9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 22, 23, 24, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39
- `src/GVLs/Generated/GVL_Persist.pvl.st` (GVL_Persist): 11, 25, 27, 41, 43, 57, 59, 63, 64, 65, 66, 67, 68, 69, 70, 73, 75, 86, 87, 88, 89, 90, 91, 92, 93, 97, 102, 103, 104, 105, 106, 107, 108, 109, 113, 116, 119, 120, 121, 122, 123, 124, 125, 126, 130, 131, 143, 144, 145, 146, 147, 148, 149, 150, 154, 158, 159, 160, 161, 162, 163, 164, 165, 169, 173, 174, 175, 176, 177, 178, 179, 180, 184, 185, 197, 198, 199, 200, 201, 202, 203, 204, 208, 212, 213, 214, 215, 216, 217, 218, 219, 223, 227, 228, 229, 230, 231, 232, 233, 234, 238, 239, 251, 252, 253, 254, 255, 256, 257, 258, 262, 266, 267, 268, 269, 270, 271, 272, 273, 277, 281, 282, 283, 284, 285, 286, 287, 288, 292, 303, 304, 305, 306, 307, 308, 309, 310, 314, 326, 327, 328, 329, 330, 331, 332, 333, 337, 341, 342, 343, 344, 345, 346, 347, 348, 352, 357, 358, 359, 360, 361, 362, 363, 364, 368, 372, 373, 374, 375, 376, 377, 378, 379, 383, 387, 388, 389, 390, 391, 392, 393, 394, 398, 408, 409, 410, 411, 412, 413, 414, 415, 419, 428, 429, 430, 431, 432, 433, 434, 435, 439, 440, 451, 452, 453, 454, 455, 456, 457, 458, 462, 466, 467, 468, 469, 470, 471, 472, 473, 477, 480, 481, 482, 483, 484, 485, 486, 487, 491, 493, 498, 499
- `src/GVLs/Station/GVL_Station.gvl.st` (GVL_Station): 10, 11
- `src/GVLs/Station/GVL_StationDefaults.gvl.st` (GVL_StationDefaults): 15, 16, 19, 21, 22, 23, 24
- `src/POUs/Field/FB_VfdAdapter_Cond/Encode.method.impl.st` (FB_VfdAdapter_Cond): 2, 3
- `src/POUs/Field/PRG_FieldIn/PRG_FieldIn.impl.st` (PRG_FieldIn): 3
- `src/POUs/Generated/PRG_Devices/PRG_Devices.impl.st` (PRG_Devices): 14
- `src/POUs/Log/FB_AlarmSummary/AckById.method.decl.st` (FB_AlarmSummary): 8
- `src/POUs/Log/FB_AlarmSummary/BuildView.method.decl.st` (FB_AlarmSummary): 19, 20, 21
- `src/POUs/Log/FB_AlarmSummary/BuildView.method.impl.st` (FB_AlarmSummary): 11, 13, 15
- `src/POUs/Log/FB_AlarmSummary/FB_AlarmSummary.decl.st` (FB_AlarmSummary): 12, 14, 19, 26, 30, 31, 39, 40, 41, 42
- `src/POUs/Log/FB_AlarmSummary/FB_AlarmSummary.impl.st` (FB_AlarmSummary): 12, 27, 31, 34, 38, 39, 40
- `src/POUs/Log/FB_AlarmSummary/FindAlarm.method.decl.st` (FB_AlarmSummary): 2, 9, 10
- `src/POUs/Log/FB_AlarmSummary/ShelveById.method.decl.st` (FB_AlarmSummary): 9
- `src/POUs/Log/FB_DeviceAudit/FB_DeviceAudit.decl.st` (FB_DeviceAudit): 9, 17, 20, 21
- `src/POUs/Log/FB_EventLog/FB_EventLog.decl.st` (FB_EventLog): 11, 13, 26
- `src/POUs/Log/FB_EventLog/LogEvent.method.impl.st` (FB_EventLog): 1, 3, 4
- `src/POUs/Log/FB_EventLog/OnAlarmEvent.method.decl.st` (FB_EventLog): 4

… и ещё 426 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Тип <code>LTIME</code> — 104</summary>

Библиотека plc-process-lib:

- `src/DUTs/Alarm/ST_AlarmEvent.dut.st` (ST_AlarmEvent): 14
- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 33, 41
- `src/Interfaces/I_TimeSource/Now.method.decl.st` (I_TimeSource): 2
- `src/POUs/Alarm/FB_Alarm/FB_Alarm.decl.st` (FB_Alarm): 28, 38, 40
- `src/POUs/Base/FB_DeviceBase/FB_DeviceBase.decl.st` (FB_DeviceBase): 19, 20, 21
- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 48, 69

Флагман kns-pump-station:

- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 156, 185
- `src/POUs/Log/FB_AlarmSummary/FB_AlarmSummary.decl.st` (FB_AlarmSummary): 32, 33
- `src/POUs/Model/FB_PlantModel/FB_PlantModel.decl.st` (FB_PlantModel): 50, 51, 52
- `src/POUs/Model/FB_VfdSim/FB_VfdSim.decl.st` (FB_VfdSim): 53, 54
- `src/POUs/Station/FB_Annunciator/FB_Annunciator.decl.st` (FB_Annunciator): 26, 35
- `src/POUs/Station/FB_PumpRotation/FB_PumpRotation.decl.st` (FB_PumpRotation): 63, 82
- `src/POUs/Time/FB_ScaledClock/AdvanceL.method.decl.st` (FB_ScaledClock): 4
- `src/POUs/Time/FB_ScaledClock/FB_ScaledClock.decl.st` (FB_ScaledClock): 12, 13, 15
- `src/POUs/Time/FB_ScaledClock/Now.method.decl.st` (FB_ScaledClock): 2, 4
- `src/POUs/Time/FB_ScaledClock/ScaledAt.method.decl.st` (FB_ScaledClock): 3, 5, 8
- `src/POUs/Time/FB_ScaledClock/SetManual.method.decl.st` (FB_ScaledClock): 7
- `src/POUs/Time/FB_ScaledClock/Update.method.decl.st` (FB_ScaledClock): 9
- `tests/POUs/Model/FB_ScaledClock_Test/AdvanceIgnoredOutsideManual.method.decl.st` (FB_ScaledClock_Test): 5, 6, 7
- `tests/POUs/Model/FB_ScaledClock_Test/DefaultsScaleOneAndSystemTime.method.decl.st` (FB_ScaledClock_Test): 5, 6, 7
- `tests/POUs/Model/FB_ScaledClock_Test/FB_ScaledClock_Test.decl.st` (FB_ScaledClock_Test): 12, 13, 14
- `tests/POUs/Model/FB_ScaledClock_Test/ManualAdvance.method.decl.st` (FB_ScaledClock_Test): 6, 7, 8
- `tests/POUs/Model/FB_ScaledClock_Test/ScaleChangeIsMonotonic.method.decl.st` (FB_ScaledClock_Test): 5
- `tests/POUs/Model/FB_ScaledClock_Test/ScaleFiftyBracketsRealTime.method.decl.st` (FB_ScaledClock_Test): 6, 7, 8, 9, 10, 11, 12, 13
- `tests/POUs/Model/FB_ScaledClock_Test/ScaleOneEqualsSystem.method.decl.st` (FB_ScaledClock_Test): 5, 6, 7

… и ещё 26 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Литералы <code>LTIME#</code>, <code>LT#</code> — 126</summary>

Библиотека plc-process-lib:

- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 33, 41
- `src/POUs/Base/FB_DeviceBase/BeginCycle.method.impl.st` (FB_DeviceBase): 6
- `src/POUs/Control/FB_PID/FB_PID.impl.st` (FB_PID): 115
- `src/POUs/Devices/FB_Motor/FB_Motor.impl.st` (FB_Motor): 132, 136, 359, 421, 426
- `src/POUs/Devices/FB_Valve/CountOperations.method.impl.st` (FB_Valve): 13, 14

Флагман kns-pump-station:

- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 156, 185
- `src/POUs/Model/FB_PlantModel/FB_PlantModel.impl.st` (FB_PlantModel): 18
- `src/POUs/Time/FB_ScaledClock/FB_ScaledClock.decl.st` (FB_ScaledClock): 15
- `tests/POUs/Log/FB_AlarmSummary_Test/TimeBackwardsRebuildsView.method.impl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_EventLog_Test/TimeBackwardsRecordedAsIs.method.impl.st` (FB_EventLog_Test): 5
- `tests/POUs/Model/FB_PlantModel_Test/TimeBackwardsHoldsState.method.impl.st` (FB_PlantModel_Test): 11
- `tests/POUs/Model/FB_ScaledClock_Test/AdvanceIgnoredOutsideManual.method.impl.st` (FB_ScaledClock_Test): 4
- `tests/POUs/Model/FB_ScaledClock_Test/FB_ScaledClock_Test.decl.st` (FB_ScaledClock_Test): 12, 13, 14
- `tests/POUs/Model/FB_ScaledClock_Test/ManualAdvance.method.impl.st` (FB_ScaledClock_Test): 11
- `tests/POUs/Model/FB_VfdSim_Test/TimeBackwardsHoldsFrequency.method.impl.st` (FB_VfdSim_Test): 9
- `tests/POUs/Station/FB_Annunciator_Test/TimeBackwardsRestartsBlink.method.impl.st` (FB_Annunciator_Test): 10
- `tests/POUs/Station/FB_Ats_Test/TimeBackwardsWindowRestarts.method.impl.st` (FB_Ats_Test): 17
- `tests/POUs/Station/FB_LevelControlPid_Test/TimeBackwardsRestartsConfirm.method.impl.st` (FB_LevelControlPid_Test): 14
- `tests/POUs/Station/FB_LevelControlStepped_Test/TimeBackwardsRestartsConfirm.method.impl.st` (FB_LevelControlStepped_Test): 5
- `tests/POUs/Station/FB_PowerRestore_Test/TimeBackwardsRestartsDelay.method.impl.st` (FB_PowerRestore_Test): 9
- `tests/POUs/Station/FB_Protections_Test/TimeBackwardsRestartsLdev.method.impl.st` (FB_Protections_Test): 13
- `tests/POUs/Station/FB_PumpProtection_Test/TimeBackwardsRestartsUnderload.method.impl.st` (FB_PumpProtection_Test): 10
- `tests/POUs/Station/FB_PumpRotation_Test/TimeBackwardsRestartsStagger.method.impl.st` (FB_PumpRotation_Test): 18
- `tests/POUs/Station/FB_StationAlarms_Test/TimeBackwardsOnDelayRestarts.method.impl.st` (FB_StationAlarms_Test): 7
- `tests/POUs/Station/FB_Ventilation_Test/TimeBackwardsRestartsOverrun.method.impl.st` (FB_Ventilation_Test): 10

… и ещё 36 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Преобразования <code>*_TO_LTIME</code>, <code>LTIME_TO_*</code> — 34</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/FB_Alarm.impl.st` (FB_Alarm): 59
- `src/POUs/Alarm/FB_Alarm/UpdateShelve.method.impl.st` (FB_Alarm): 6, 7, 27
- `src/POUs/Control/FB_PID/FB_PID.impl.st` (FB_PID): 111, 115
- `src/POUs/Devices/FB_Motor/FB_Motor.impl.st` (FB_Motor): 77, 78, 128, 235, 359, 367, 369, 429, 431
- `src/POUs/Time/FB_Delay/FB_Delay.impl.st` (FB_Delay): 16, 28
- `src/POUs/Time/FB_FakeTime/Advance.method.impl.st` (FB_FakeTime): 1
- `src/POUs/Util/F_LTimeToSec/F_LTimeToSec.impl.st` (F_LTimeToSec): 1

Флагман kns-pump-station:

- `src/POUs/Log/FB_AlarmSummary/FB_AlarmSummary.impl.st` (FB_AlarmSummary): 51
- `src/POUs/Model/FB_PlantModel/FB_PlantModel.impl.st` (FB_PlantModel): 84, 85
- `src/POUs/Station/FB_Annunciator/FB_Annunciator.impl.st` (FB_Annunciator): 43, 45
- `src/POUs/Station/FB_PumpRotation/FB_PumpRotation.impl.st` (FB_PumpRotation): 222, 251
- `src/POUs/Time/FB_ScaledClock/ScaledAt.method.impl.st` (FB_ScaledClock): 12
- `tests/POUs/Model/FB_PlantModel_Test/OverflowTimeResolvedBySubsteps.method.impl.st` (FB_PlantModel_Test): 9
- `tests/POUs/Model/FB_ScaledClock_Test/ScaleFiftyBracketsRealTime.method.impl.st` (FB_ScaledClock_Test): 17, 18, 19

</details>

<details><summary><code>LINT</code>, <code>ULINT</code>, <code>LWORD</code> — 12</summary>

Библиотека plc-process-lib:

- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 117, 119

Флагман kns-pump-station:

- `src/DUTs/Log/ST_AlarmViewRow.dut.st` (ST_AlarmViewRow): 13
- `src/DUTs/Log/ST_EventRecord.dut.st` (ST_EventRecord): 18
- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 31
- `src/POUs/Log/FB_AlarmSummary/FB_AlarmSummary.decl.st` (FB_AlarmSummary): 28
- `src/POUs/Log/FB_EventLog/Store.method.decl.st` (FB_EventLog): 14
- `src/POUs/Log/F_UtcNowMs/F_UtcNowMs.decl.st` (F_UtcNowMs): 6, 8
- `src/POUs/Log/F_UtcToIso/F_UtcToIso.decl.st` (F_UtcToIso): 10, 29
- `src/POUs/Station/FB_Annunciator/FB_Annunciator.decl.st` (FB_Annunciator): 36

</details>

<details><summary><code>POINTER TO</code> — 7</summary>

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLogCsv/AppendText.method.decl.st` (FB_EventLogCsv): 7
- `tests/POUs/Log/FB_EventLogCsv_Test/AppendExpected.method.decl.st` (FB_EventLogCsv_Test): 11
- `tests/POUs/Station/FB_ControlSelector_Test/GarbageMethodIsStepped.method.decl.st` (FB_ControlSelector_Test): 5
- `tests/POUs/Station/FB_ControlSelector_Test/ManualModeAlwaysManual.method.decl.st` (FB_ControlSelector_Test): 6
- `tests/POUs/Station/FB_F_StationCfgCheck_Test/AlarmBit.method.decl.st` (FB_F_StationCfgCheck_Test): 7
- `tests/POUs/Station/FB_F_StationCfgCheck_Test/RotationBit.method.decl.st` (FB_F_StationCfgCheck_Test): 8
- `tests/POUs/Station/FB_StationMode_Test/GarbageRetainSanitized.method.decl.st` (FB_StationMode_Test): 9

</details>

<details><summary>Структуры (<code>STRUCT</code>) — 44</summary>

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

Флагман kns-pump-station:

- `src/DUTs/Log/ST_AlarmView.dut.st` (ST_AlarmView): 7
- `src/DUTs/Log/ST_AlarmViewRow.dut.st` (ST_AlarmViewRow): 6
- `src/DUTs/Log/ST_EventFeed.dut.st` (ST_EventFeed): 9
- `src/DUTs/Log/ST_EventRecord.dut.st` (ST_EventRecord): 7
- `src/DUTs/Log/ST_EventView.dut.st` (ST_EventView): 6
- `src/DUTs/Sim/ST_FaultInjection.dut.st` (ST_FaultInjection): 8
- `src/DUTs/Sim/ST_PlantIo.dut.st` (ST_PlantIo): 9
- `src/DUTs/Sim/ST_PumpModelCfg.dut.st` (ST_PumpModelCfg): 8
- `src/DUTs/Sim/ST_SimCfg.dut.st` (ST_SimCfg): 7
- `src/DUTs/Sim/ST_SimCmd.dut.st` (ST_SimCmd): 7
- `src/DUTs/Sim/ST_SimSts.dut.st` (ST_SimSts): 7
- `src/DUTs/Sim/ST_StormEvent.dut.st` (ST_StormEvent): 7
- `src/DUTs/Station/ST_StationCfg.dut.st` (ST_StationCfg): 9
- `src/DUTs/Station/ST_StationCmd.dut.st` (ST_StationCmd): 8
- `src/DUTs/Station/ST_StationRetain.dut.st` (ST_StationRetain): 8
- `src/DUTs/Station/ST_StationSts.dut.st` (ST_StationSts): 7

… и ещё 19 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Объединения (<code>UNION</code>) — 5</summary>

Библиотека plc-process-lib:

- `src/DUTs/Common/U_RealBits.dut.st` (U_RealBits): 7
- `tests/DUTs/AiDi/U_AiDiTestEnum.dut.st` (U_AiDiTestEnum): 9
- `tests/DUTs/Pid/U_TestPidEnumInt.dut.st` (U_TestPidEnumInt): 8
- `tests/DUTs/TestDevice/U_TestEnumInt.dut.st` (U_TestEnumInt): 8
- `tests/DUTs/Valves/U_TestValveEnum.dut.st` (U_TestValveEnum): 10

</details>

<details><summary>Перечисления — 35</summary>

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

Флагман kns-pump-station:

- `src/DUTs/Log/E_EventKind.dut.st` (E_EventKind): 7
- `src/DUTs/Log/E_LogExportState.dut.st` (E_LogExportState): 7
- `src/DUTs/Log/E_StationEvent.dut.st` (E_StationEvent): 7
- `src/DUTs/Sim/E_SimAiFault.dut.st` (E_SimAiFault): 8
- `src/DUTs/Sim/E_SimFloatStuck.dut.st` (E_SimFloatStuck): 7
- `src/DUTs/Station/E_ControlAct.dut.st` (E_ControlAct): 9
- `src/DUTs/Station/E_ControlMethod.dut.st` (E_ControlMethod): 8
- `src/DUTs/Station/E_PumpRole.dut.st` (E_PumpRole): 7
- `src/DUTs/Station/E_RotationMode.dut.st` (E_RotationMode): 7
- `src/DUTs/Station/E_StationAlarm.dut.st` (E_StationAlarm): 8
- `src/DUTs/Station/E_StationMode.dut.st` (E_StationMode): 8

… и ещё 10 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary>Перечисления с базовым типом (<code>(…) INT</code>) — 35</summary>

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

Флагман kns-pump-station:

- `src/DUTs/Log/E_EventKind.dut.st` (E_EventKind): 7
- `src/DUTs/Log/E_LogExportState.dut.st` (E_LogExportState): 7
- `src/DUTs/Log/E_StationEvent.dut.st` (E_StationEvent): 7
- `src/DUTs/Sim/E_SimAiFault.dut.st` (E_SimAiFault): 8
- `src/DUTs/Sim/E_SimFloatStuck.dut.st` (E_SimFloatStuck): 7
- `src/DUTs/Station/E_ControlAct.dut.st` (E_ControlAct): 9
- `src/DUTs/Station/E_ControlMethod.dut.st` (E_ControlMethod): 8
- `src/DUTs/Station/E_PumpRole.dut.st` (E_PumpRole): 7
- `src/DUTs/Station/E_RotationMode.dut.st` (E_RotationMode): 7
- `src/DUTs/Station/E_StationAlarm.dut.st` (E_StationAlarm): 8
- `src/DUTs/Station/E_StationMode.dut.st` (E_StationMode): 8

… и ещё 10 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>VAR_IN_OUT</code> — 40</summary>

Библиотека plc-process-lib:

- `src/POUs/Base/FB_DeviceBase/FinishCycle.method.decl.st` (FB_DeviceBase): 12
- `src/POUs/Base/FB_DeviceBase/ProcessMode.method.decl.st` (FB_DeviceBase): 11
- `src/POUs/Base/FB_DeviceBase/RunAlarms.method.decl.st` (FB_DeviceBase): 9
- `src/POUs/Base/FB_DeviceBase/SwitchRemoteMode.method.decl.st` (FB_DeviceBase): 8
- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 22
- `src/POUs/Devices/FB_AnalogInput/CallLimit.method.decl.st` (FB_AnalogInput): 11
- `src/POUs/Devices/FB_AnalogInput/FB_AnalogInput.decl.st` (FB_AnalogInput): 18
- `src/POUs/Devices/FB_ControlValve/FB_ControlValve.decl.st` (FB_ControlValve): 20

Флагман kns-pump-station:

- `src/POUs/Log/FB_AlarmSummary/BuildView.method.decl.st` (FB_AlarmSummary): 4
- `src/POUs/Log/FB_AlarmSummary/FB_AlarmSummary.decl.st` (FB_AlarmSummary): 22
- `src/POUs/Log/FB_EventLog/FillFeed.method.decl.st` (FB_EventLog): 4
- `src/POUs/Log/FB_EventLog/FillView.method.decl.st` (FB_EventLog): 4
- `src/POUs/Log/FB_EventLogCsv/FB_EventLogCsv.decl.st` (FB_EventLogCsv): 13
- `src/POUs/Model/FB_PlantModel/FB_PlantModel.decl.st` (FB_PlantModel): 24
- `src/POUs/Station/FB_PumpRotation/FB_PumpRotation.decl.st` (FB_PumpRotation): 31
- `src/POUs/Station/FB_StationCore/FB_StationCore.decl.st` (FB_StationCore): 59
- `src/POUs/Station/FB_StationMode/FB_StationMode.decl.st` (FB_StationMode): 19
- `tests/POUs/Log/FB_EventLogCsv_Test/AppendExpected.method.decl.st` (FB_EventLogCsv_Test): 6
- `tests/POUs/Station/FB_LevelControlPid_Test/Run.method.decl.st` (FB_LevelControlPid_Test): 3
- `tests/POUs/Station/FB_LevelControlStepped_Test/Run.method.decl.st` (FB_LevelControlStepped_Test): 3
- `tests/POUs/Station/FB_PowerRestore_Test/Run.method.decl.st` (FB_PowerRestore_Test): 3
- `tests/POUs/Station/FB_Protections_Test/Run.method.decl.st` (FB_Protections_Test): 3
- `tests/POUs/Station/FB_PumpProtection_Test/Run.method.decl.st` (FB_PumpProtection_Test): 3
- `tests/POUs/Station/FB_PumpRotation_Test/Cycle.method.decl.st` (FB_PumpRotation_Test): 4
- `tests/POUs/Station/FB_StationCore_Test/Cycle.method.decl.st` (FB_StationCore_Test): 5

… и ещё 15 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>VAR_IN_OUT CONSTANT</code> — 39</summary>

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

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLog/OnAlarmEvent.method.decl.st` (FB_EventLog): 3
- `src/POUs/Model/FB_InflowProfile/FB_InflowProfile.decl.st` (FB_InflowProfile): 13
- `src/POUs/Model/FB_PlantModel/FB_PlantModel.decl.st` (FB_PlantModel): 21
- `src/POUs/Model/F_FaultInjEqual/F_FaultInjEqual.decl.st` (F_FaultInjEqual): 10
- `src/POUs/Station/FB_Ats/FB_Ats.decl.st` (FB_Ats): 23
- `src/POUs/Station/FB_LevelControlPid/FB_LevelControlPid.decl.st` (FB_LevelControlPid): 22
- `src/POUs/Station/FB_LevelControlStepped/FB_LevelControlStepped.decl.st` (FB_LevelControlStepped): 18
- `src/POUs/Station/FB_PowerRestore/FB_PowerRestore.decl.st` (FB_PowerRestore): 19
- `src/POUs/Station/FB_Protections/FB_Protections.decl.st` (FB_Protections): 26
- `src/POUs/Station/FB_PumpProtection/FB_PumpProtection.decl.st` (FB_PumpProtection): 18
- `src/POUs/Station/FB_PumpRotation/FB_PumpRotation.decl.st` (FB_PumpRotation): 28
- `src/POUs/Station/FB_StationAlarms/FB_StationAlarms.decl.st` (FB_StationAlarms): 19
- `src/POUs/Station/FB_StationCore/ChangedParam.method.decl.st` (FB_StationCore): 6
- `src/POUs/Station/FB_Ventilation/FB_Ventilation.decl.st` (FB_Ventilation): 15
- `src/POUs/Station/F_StationCfgCheck/F_StationCfgCheck.decl.st` (F_StationCfgCheck): 11

… и ещё 14 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>VAR_INST</code> — 39</summary>

Флагман kns-pump-station:

- `tests/POUs/Field/FB_PlcStartAdoption_Test/AdoptedInGeneratedOrder.method.decl.st` (FB_PlcStartAdoption_Test): 14
- `tests/POUs/Field/FB_PlcStartAdoption_Test/PowerDeviceAfterPumpStopsRunningPump.method.decl.st` (FB_PlcStartAdoption_Test): 13
- `tests/POUs/Log/FB_AlarmSummary_Test/AckByIdDeviceStationPid.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/CountsByPriority.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/EmptyDefaults.method.decl.st` (FB_AlarmSummary_Test): 3
- `tests/POUs/Log/FB_AlarmSummary_Test/NewHighSeqOnlyOnTransition.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/PrioUnackHighest.method.decl.st` (FB_AlarmSummary_Test): 3
- `tests/POUs/Log/FB_AlarmSummary_Test/PrioUnackHighestBeforeLower.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/ShelveByIdRespectsTShelveMax.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/ShelveByIdUsesFullTShelveMax.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/StationSlotsBeyondDeviceLimit.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/TimeBackwardsRebuildsView.method.decl.st` (FB_AlarmSummary_Test): 3
- `tests/POUs/Log/FB_AlarmSummary_Test/UnshelveById.method.decl.st` (FB_AlarmSummary_Test): 3
- `tests/POUs/Log/FB_AlarmSummary_Test/ViewLimitedToRows.method.decl.st` (FB_AlarmSummary_Test): 3
- `tests/POUs/Log/FB_AlarmSummary_Test/ViewNewerFirstInGroup.method.decl.st` (FB_AlarmSummary_Test): 4
- `tests/POUs/Log/FB_AlarmSummary_Test/ViewPeriodRespected.method.decl.st` (FB_AlarmSummary_Test): 3
- `tests/POUs/Log/FB_AlarmSummary_Test/ViewSortedUnackFirst.method.decl.st` (FB_AlarmSummary_Test): 3
- `tests/POUs/Log/FB_DeviceAudit_Test/AuditLogsModeChange.method.decl.st` (FB_DeviceAudit_Test): 3
- `tests/POUs/Log/FB_DeviceAudit_Test/LargeDevNoValueNoOverflow.method.decl.st` (FB_DeviceAudit_Test): 4
- `tests/POUs/Log/FB_DeviceAudit_Test/NoEventOnFirstCall.method.decl.st` (FB_DeviceAudit_Test): 3
- `tests/POUs/Log/FB_EventLogCsv_Test/EmptySnapshotHeaderOnly.method.decl.st` (FB_EventLogCsv_Test): 3
- `tests/POUs/Log/FB_EventLogCsv_Test/ErrorOnBadPathReported.method.decl.st` (FB_EventLogCsv_Test): 4
- `tests/POUs/Log/FB_EventLogCsv_Test/ReadBackMatchesSnapshot.method.decl.st` (FB_EventLogCsv_Test): 4
- `tests/POUs/Log/FB_EventLogCsv_Test/SlowTaskRequestHandshake.method.decl.st` (FB_EventLogCsv_Test): 5
- `tests/POUs/Log/FB_EventLogCsv_Test/WritesHeaderAndAllLines.method.decl.st` (FB_EventLogCsv_Test): 3

… и ещё 14 файлов — полный список в `docs/inventory.json`.

</details>

<details><summary><code>VAR_TEMP</code> — 21</summary>

Библиотека plc-process-lib:

- `src/POUs/Alarm/FB_Alarm/FB_Alarm.decl.st` (FB_Alarm): 45
- `src/POUs/Control/FB_PID/FB_PID.decl.st` (FB_PID): 61
- `src/POUs/Devices/FB_AnalogInput/FB_AnalogInput.decl.st` (FB_AnalogInput): 54
- `src/POUs/Devices/FB_ControlValve/FB_ControlValve.decl.st` (FB_ControlValve): 57
- `src/POUs/Devices/FB_DigitalInput/FB_DigitalInput.decl.st` (FB_DigitalInput): 32
- `src/POUs/Devices/FB_Motor/FB_Motor.decl.st` (FB_Motor): 87
- `src/POUs/Devices/FB_Valve/FB_Valve.decl.st` (FB_Valve): 103
- `src/POUs/Time/FB_Delay/FB_Delay.decl.st` (FB_Delay): 27
- `src/POUs/Util/FB_LimitMonitor/FB_LimitMonitor.decl.st` (FB_LimitMonitor): 24
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 64

Флагман kns-pump-station:

- `src/POUs/Station/FB_Annunciator/FB_Annunciator.decl.st` (FB_Annunciator): 29
- `src/POUs/Station/FB_Ats/FB_Ats.decl.st` (FB_Ats): 39
- `src/POUs/Station/FB_LevelControlPid/FB_LevelControlPid.decl.st` (FB_LevelControlPid): 43
- `src/POUs/Station/FB_LevelControlStepped/FB_LevelControlStepped.decl.st` (FB_LevelControlStepped): 33
- `src/POUs/Station/FB_PowerRestore/FB_PowerRestore.decl.st` (FB_PowerRestore): 40
- `src/POUs/Station/FB_Protections/FB_Protections.decl.st` (FB_Protections): 53
- `src/POUs/Station/FB_PumpProtection/FB_PumpProtection.decl.st` (FB_PumpProtection): 29
- `src/POUs/Station/FB_PumpRotation/FB_PumpRotation.decl.st` (FB_PumpRotation): 76
- `src/POUs/Station/FB_StationAlarms/FB_StationAlarms.decl.st` (FB_StationAlarms): 31
- `src/POUs/Station/FB_StationCore/FB_StationCore.decl.st` (FB_StationCore): 108
- `src/POUs/Station/FB_StationMode/FB_StationMode.decl.st` (FB_StationMode): 34

</details>

<details><summary>Локальные константы (<code>VAR CONSTANT</code>) — 21</summary>

Библиотека plc-process-lib:

- `tests/POUs/Helpers/FB_FopdtModel/FB_FopdtModel.decl.st` (FB_FopdtModel): 10
- `tests/POUs/Helpers/FB_TestDevice/FB_TestDevice.decl.st` (FB_TestDevice): 13
- `tests/POUs/Helpers/FB_TestSink/FB_TestSink.decl.st` (FB_TestSink): 8
- `tests/POUs/Suites/FB_Runtime_Test/FB_Runtime_Test.decl.st` (FB_Runtime_Test): 12

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLogCsv/FB_EventLogCsv.decl.st` (FB_EventLogCsv): 36
- `src/POUs/Log/F_AlarmCode/F_AlarmCode.decl.st` (F_AlarmCode): 19
- `src/POUs/Log/F_EventCsvLine/F_EventCsvLine.decl.st` (F_EventCsvLine): 17
- `src/POUs/Log/F_UtcToIso/F_UtcToIso.decl.st` (F_UtcToIso): 28
- `tests/POUs/Fakes/FB_FakeEventSink/FB_FakeEventSink.decl.st` (FB_FakeEventSink): 7
- `tests/POUs/Field/FB_PlcStartAdoption_Test/FB_PlcStartAdoption_Test.decl.st` (FB_PlcStartAdoption_Test): 11
- `tests/POUs/Field/FB_VfdAdapter_Cond_Test/FB_VfdAdapter_Cond_Test.decl.st` (FB_VfdAdapter_Cond_Test): 8
- `tests/POUs/Log/FB_DeviceAudit_Test/FB_DeviceAudit_Test.decl.st` (FB_DeviceAudit_Test): 8
- `tests/POUs/Log/FB_EventLogCsv_Test/FB_EventLogCsv_Test.decl.st` (FB_EventLogCsv_Test): 9
- `tests/POUs/Log/FB_EventLog_Test/FB_EventLog_Test.decl.st` (FB_EventLog_Test): 10
- `tests/POUs/Model/FB_HydraulicSolver_Test/FB_HydraulicSolver_Test.decl.st` (FB_HydraulicSolver_Test): 10
- `tests/POUs/Model/FB_InflowProfile_Test/FB_InflowProfile_Test.decl.st` (FB_InflowProfile_Test): 8
- `tests/POUs/Model/FB_PlantModel_Test/FB_PlantModel_Test.decl.st` (FB_PlantModel_Test): 11
- `tests/POUs/Model/FB_ScaledClock_Test/FB_ScaledClock_Test.decl.st` (FB_ScaledClock_Test): 9
- `tests/POUs/Model/FB_StormGenerator_Test/FB_StormGenerator_Test.decl.st` (FB_StormGenerator_Test): 9
- `tests/POUs/Model/FB_TankModel_Test/FB_TankModel_Test.decl.st` (FB_TankModel_Test): 8
- `tests/POUs/Model/FB_VfdSim_Test/FB_VfdSim_Test.decl.st` (FB_VfdSim_Test): 11

</details>

<details><summary><code>VAR_GLOBAL CONSTANT</code> — 13</summary>

Библиотека plc-process-lib:

- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 11, 63, 75, 106, 121, 159, 192, 219

Флагман kns-pump-station:

- `src/GVLs/GVL_Const.gvl.st` (GVL_Const): 8
- `src/GVLs/Generated/GVL_CfgProject.gvl.st` (GVL_CfgProject): 6
- `src/GVLs/Generated/GVL_DevIdx.gvl.st` (GVL_DevIdx): 6
- `src/GVLs/Generated/GVL_DeviceList.gvl.st` (GVL_DeviceList): 7
- `src/GVLs/Station/GVL_StationDefaults.gvl.st` (GVL_StationDefaults): 9

</details>

<details><summary>GVL с <code>VAR_GLOBAL</code> и <code>VAR_GLOBAL CONSTANT</code> в одном объекте — 1</summary>

Флагман kns-pump-station:

- `src/GVLs/Generated/GVL_DeviceList.gvl.st` (GVL_DeviceList): 7

</details>

<details><summary>Оператор <code>LTIME()</code> (монотонное время) — 16</summary>

Библиотека plc-process-lib:

- `src/POUs/Time/FB_SystemTime/Now.method.impl.st` (FB_SystemTime): 1

Флагман kns-pump-station:

- `src/POUs/Time/FB_ScaledClock/Now.method.impl.st` (FB_ScaledClock): 6
- `src/POUs/Time/FB_ScaledClock/SetManual.method.impl.st` (FB_ScaledClock): 8
- `src/POUs/Time/FB_ScaledClock/Update.method.impl.st` (FB_ScaledClock): 7
- `tests/POUs/Model/FB_ScaledClock_Test/AdvanceIgnoredOutsideManual.method.impl.st` (FB_ScaledClock_Test): 5, 7
- `tests/POUs/Model/FB_ScaledClock_Test/DefaultsScaleOneAndSystemTime.method.impl.st` (FB_ScaledClock_Test): 4, 6
- `tests/POUs/Model/FB_ScaledClock_Test/ManualAdvance.method.impl.st` (FB_ScaledClock_Test): 10, 13
- `tests/POUs/Model/FB_ScaledClock_Test/ScaleFiftyBracketsRealTime.method.impl.st` (FB_ScaledClock_Test): 4, 6, 13, 15
- `tests/POUs/Model/FB_ScaledClock_Test/ScaleOneEqualsSystem.method.impl.st` (FB_ScaledClock_Test): 5, 7

</details>

<details><summary><code>SIZEOF</code> — 38</summary>

Библиотека plc-process-lib:

- `tests/POUs/Suites/FB_Common_Test/SizeOfAlarmCfgIs16.method.impl.st` (FB_Common_Test): 3, 4
- `tests/POUs/Suites/FB_Common_Test/SizeOfCfgMatchesReference.method.impl.st` (FB_Common_Test): 3, 4, 5, 6, 7, 8, 9
- `tests/POUs/Suites/FB_Common_Test/SizeOfCmdMatchesReference.method.impl.st` (FB_Common_Test): 3, 4, 5, 6, 7, 8, 9
- `tests/POUs/Suites/FB_Common_Test/SizeOfDeviceRetainIs36.method.impl.st` (FB_Common_Test): 3
- `tests/POUs/Suites/FB_Common_Test/SizeOfStsMatchesRegisterMap.method.impl.st` (FB_Common_Test): 3, 4, 5, 6, 7, 8, 9
- `tests/POUs/Suites/FB_DeviceBase_Test/AlarmSlotArraysMatchDevAlarmsMax.method.impl.st` (FB_DeviceBase_Test): 3, 4, 5, 7, 9
- `tests/POUs/Suites/FB_Util_Test/StartsWindowRingCapacityMatchesConst.method.impl.st` (FB_Util_Test): 3

Флагман kns-pump-station:

- `tests/POUs/Log/FB_EventLogCsv_Test/ReadBackMatchesSnapshot.method.impl.st` (FB_EventLogCsv_Test): 34
- `tests/POUs/Log/FB_EventLog_Test/EventRecordSizeIs40.method.impl.st` (FB_EventLog_Test): 3, 4, 5
- `tests/POUs/Station/FB_StationCore_Test/StationDefaultsMatchTypeDefaults.method.impl.st` (FB_StationCore_Test): 14, 16
- `tests/POUs/Station/FB_StationCore_Test/StationStsSizeIs72.method.impl.st` (FB_StationCore_Test): 3

</details>

<details><summary><code>ADR</code> — 10</summary>

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLogCsv/AppendText.method.impl.st` (FB_EventLogCsv): 1
- `src/POUs/Log/FB_EventLogCsv/FB_EventLogCsv.impl.st` (FB_EventLogCsv): 43
- `tests/POUs/Log/FB_EventLogCsv_Test/AppendExpected.method.impl.st` (FB_EventLogCsv_Test): 1
- `tests/POUs/Log/FB_EventLogCsv_Test/ReadBackMatchesSnapshot.method.impl.st` (FB_EventLogCsv_Test): 34
- `tests/POUs/Station/FB_ControlSelector_Test/GarbageMethodIsStepped.method.impl.st` (FB_ControlSelector_Test): 3
- `tests/POUs/Station/FB_ControlSelector_Test/ManualModeAlwaysManual.method.impl.st` (FB_ControlSelector_Test): 7
- `tests/POUs/Station/FB_F_StationCfgCheck_Test/AlarmBit.method.impl.st` (FB_F_StationCfgCheck_Test): 5
- `tests/POUs/Station/FB_F_StationCfgCheck_Test/RotationBit.method.impl.st` (FB_F_StationCfgCheck_Test): 5
- `tests/POUs/Station/FB_StationMode_Test/GarbageRetainSanitized.method.impl.st` (FB_StationMode_Test): 8, 10

</details>

<details><summary>Разыменование <code>^</code> — 8</summary>

Флагман kns-pump-station:

- `src/POUs/Log/FB_EventLogCsv/AppendText.method.impl.st` (FB_EventLogCsv): 4
- `tests/POUs/Log/FB_EventLogCsv_Test/AppendExpected.method.impl.st` (FB_EventLogCsv_Test): 4
- `tests/POUs/Station/FB_ControlSelector_Test/GarbageMethodIsStepped.method.impl.st` (FB_ControlSelector_Test): 4
- `tests/POUs/Station/FB_ControlSelector_Test/ManualModeAlwaysManual.method.impl.st` (FB_ControlSelector_Test): 8
- `tests/POUs/Station/FB_F_StationCfgCheck_Test/AlarmBit.method.impl.st` (FB_F_StationCfgCheck_Test): 6
- `tests/POUs/Station/FB_F_StationCfgCheck_Test/RotationBit.method.impl.st` (FB_F_StationCfgCheck_Test): 6
- `tests/POUs/Station/FB_StationMode_Test/GarbageRetainSanitized.method.impl.st` (FB_StationMode_Test): 9, 11

</details>

<details><summary><code>PERSISTENT</code> — 39</summary>

Флагман kns-pump-station:

- `src/GVLs/Generated/GVL_Persist.pvl.st` (GVL_Persist): 9, 11, 25, 27, 41, 43, 57, 59, 73, 75, 97, 113, 130, 154, 169, 184, 208, 223, 238, 262, 277, 292, 314, 337, 352, 368, 383, 398, 419, 439, 462, 477, 491, 493, 495, 496, 498, 499, 500

</details>

<details><summary>Объект Persistent Variables (<code>*.pvl.st</code>) — 1</summary>

Флагман kns-pump-station:

- `src/GVLs/Generated/GVL_Persist.pvl.st` (GVL_Persist): 1

</details>

<details><summary>Задачи из <code>tools/codesys/config.json</code> — 6</summary>

Библиотека plc-process-lib:

- `tools/codesys/config.json` (normal): 69, 81

Флагман kns-pump-station:

- `tools/codesys/config.json` (normal): 44, 46, 47, 52

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
| <a id="ref-f28"></a>F28 | Атрибут вендора `ps.add_redundancy`; REFERENCE, POINTER и массивы с ними не резервируются | DPA-302.4 v2.11, с. 46, 57 | [ссылка](https://reglab.ru/upload/iblock/28f/tmu37n4jz4w5oxepmx0431vb5q5yo6xw/Redundancy-User-Guide-_DPA_302_4_v2_11_rus.pdf) |
| <a id="ref-f29"></a>F29 | `'strict'`, `'call_after_init'`, `'hide'`, `'no_check'`, `'init_namespace'`, `'monitoring'` и `{IF defined(...)}` в документации не найдены | DPA-302 v2.20, с. 43 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f30"></a>F30 | В таблицах OPC UA есть `LWORD`, `LINT/ULINT`, `WSTRING` и структура `ua_var_ltime` для `LTIME` | DPA-302.6 v1.7, с. 7–10 | [ссылка](https://reglab.ru/upload/iblock/57b/dvvplmt0qby4duccefw4vyi9j3u59ziu/OPC_UA_User_Guide_DPA_302_6_v1_7_rus.pdf) |
| <a id="ref-f31"></a>F31 | `REFERENCE TO` и `POINTER TO` используются в интерфейсах библиотек и примерах вендора | DPA-302 v2.20, с. 311–322; DPA-302.1 v1.7, с. 22 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f32"></a>F32 | DUT: структура, перечисление, псевдоним, объединение; `BIT` — в структурах и ФБ, не в массивах | курс, 5.8 | [ссылка](https://reglab.ru/upload/materialy-kursa/strukturnye_tipy.htm) |
| <a id="ref-f33"></a>F33 | Перечисления с явными значениями и `VAR_STAT` поддерживаются (видны в OPC UA) | DPA-302.6 v1.7, с. 12–14 | [ссылка](https://reglab.ru/upload/iblock/57b/dvvplmt0qby4duccefw4vyi9j3u59ziu/OPC_UA_User_Guide_DPA_302_6_v1_7_rus.pdf) |
| <a id="ref-f34"></a>F34 | Перечисления с базовым типом, `STRUCT … EXTENDS`, `LDATE/LTOD/LDT`, литералы и арифметика `LTIME` в документации не описаны | отсутствие в документах; проверить вручную | первоисточника нет (вывод исследования) |
| <a id="ref-f38"></a>F38 | Тёплый сброс сохраняет RETAIN и PERSISTENT RETAIN, холодный — только PERSISTENT RETAIN, заводской — ничего | DPA-302 v2.20, с. 193–194, табл. 8 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f40"></a>F40 | RETAIN и PERSISTENT — общая область: SRAM до 1 МБ или файл до 100 МБ (`[PsRetain]`, `StorageSize` по умолчанию 1 КБ); запись синхронизируется при любом изменении | DPA-302 v2.20, с. 194–195, 291 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f41"></a>F41 | PERSISTENT RETAIN объявляются в объекте «Persistent-переменные…» (`PersistentVars`) | DPA-302 v2.20, с. 195; курс, 5.6 | [ссылка](https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf) |
| <a id="ref-f47"></a>F47 | PLCopenXML в CODESYS — подмножество; при экспорте VAR_GLOBAL и VAR_GLOBAL CONSTANT нельзя держать в одном списке | CODESYS Online Help, Exporting and Importing Projects; Command: Export PLCopenXML | [ссылка](https://content.helpme-codesys.com/en/CODESYS%20Development%20System/_cds_cmd_export_plcopenxml.html) |
| <a id="ref-f50"></a>F50 | В учебных проектах вендора используются Standard (`R_TRIG`, `LEN`), Standard64 (`WLEN`) и Util | курс, 4.14, 5.13, 17.16 | [ссылка](https://reglab.ru/upload/materialy-kursa/okno_programmnogo_bloka_s_kodom_na_yazyke_st.htm) |
| <a id="ref-f52"></a>F52 | Время: SysTime, SysTimeRtc, PsTime (`PsTimeGetUtcTimeNs` — UTC в нс, `ULINT`) | курс, 15.2; DPA-302 v2.20, с. 234, 390 | [ссылка](https://reglab.ru/upload/materialy-kursa/biblioteki_dlya_raboty_s_datoj_i_vremenem.htm) |
| <a id="ref-f53"></a>F53 | CAA File в документации нет; плейсхолдер в описании устройства разрешается на CAA File 3.5.17.0 | пакет 1.7.2.6, REGUL R500 71-W.devdesc.xml | [ссылка](https://reglab.ru/upload/iblock/0fd/bkk3sngi1qu0kz62c3j1so8iykr78fr6/RegLab_Ltd_Regul_1.7.2.6.package) |
| <a id="ref-f73"></a>F73 | coUnit 1.2.0.0 ссылается на 16 библиотек, в том числе Breakpoint Logging Functions 3.5.5.0 (фиксированная версия), IECStringUtils, Base Interfaces | по исходникам coUnit (forge.codesys.com/lib/counit); наличие в Astra.IDE — проверить вручную | [ссылка](https://forge.codesys.com/lib/counit/) |
| <a id="ref-f78"></a>F78 | В приложении есть «Менеджер библиотек», свои библиотеки и репозиторий библиотек | курс, 4.4 | [ссылка](https://reglab.ru/upload/materialy-kursa/struktura_dereva_proekta.htm) |
| <a id="ref-f79"></a>F79 | Вендор пишет полные имена с пространствами имён; имена функций вендора менялись между версиями | DPA-302.6, с. 9–11; DPA-302 v2.20, с. 9, 390, 393 | [ссылка](https://reglab.ru/upload/iblock/57b/dvvplmt0qby4duccefw4vyi9j3u59ziu/OPC_UA_User_Guide_DPA_302_6_v1_7_rus.pdf) |
| <a id="ref-f85"></a>F85 | В патче 1.7.2.5 добавлен запрет на ссылки и указатели в символьной конфигурации | reglab.ru/soft, «Патч 1.7.2.5» | [ссылка](https://reglab.ru/soft/) |

### Риски

| Риск | Кратко |
|---|---|
| <a id="ref-r8"></a>R8 | OPC UA: ФБ с REFERENCE/POINTER (возможно, и с интерфейсными переменными) ломают символьную конфигурацию — фасад GVL с плоскими типами |
| <a id="ref-r10"></a>R10 | PERSISTENT синхронизируются при каждой записи — копить приращение и переносить с периодом |
| <a id="ref-r11"></a>R11 | Объект PersistentVars не создаётся автоматически — вручную или импортом PLCopenXML |
| <a id="ref-r13"></a>R13 | Приоритеты задач REGUL 0–15, 0 и 1 зарезервированы — таблица соответствия задач |
| <a id="ref-r15"></a>R15 | Наследование ФБ не подтверждено — композиция и интерфейсы, каждая правка с `// PORT:` |
| <a id="ref-r16"></a>R16 | Атрибуты strict, call_after_init не описаны — проверить компиляцией и поведением |
| <a id="ref-r17"></a>R17 | Перечисления с базовым типом, STRUCT EXTENDS не описаны — явные значения, композиция |
| <a id="ref-r18"></a>R18 | coUnit может не собраться — тесты логики в CODESYS 3.5.17.30, на REGUL — интеграционные |
| <a id="ref-r19"></a>R19 | CAA File не описана — SysFile в отдельной задаче с низким приоритетом |
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
| <a id="ref-c10"></a>C10 | CAA File: запись CSV на ВПЛК |
| <a id="ref-c11"></a>C11 | `LTIME`: литералы, арифметика, преобразования, таймеры на LTIME |
| <a id="ref-c13"></a>C13 | `VAR_IN_OUT` (в том числе `CONSTANT`) с массивами и строками |
| <a id="ref-c14"></a>C14 | `{attribute 'linkalways'}` у GVL тестов: GVL без ссылок из кода попадает в приложение (пункт добавлен в чек-лист миграции по итогам инвентаризации) |
| <a id="ref-d1"></a>D1 | Создать «Persistent-переменные…» и добавить пути экземпляров |
| <a id="ref-g4"></a>G4 | Ошибка символьной конфигурации на ФБ с REFERENCE/POINTER и интерфейсными переменными |
| <a id="ref-h2"></a>H2 | Установить coUnit 1.2.0.0 и собрать тестовый проект |
| <a id="ref-h3"></a>H3 | Прогон coUnit на ВПЛК: результаты и путь к xUnit-файлу |
| <a id="ref-j1"></a>J1 | Допустимые приоритеты задач на выбранном ЦП, сторожевой таймер, системные задачи |

### Разделы исследования

- <a id="ref-29"></a>§2.9 — раздел 2.9 исследования (Modbus): `ModbusUserRequest2` с буфером `ADR`/`SIZEOF` (DPA-302.1 v1.7)
