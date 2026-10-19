"""Справочник для tools/inventory.py: возможности CODESYS, риск переноса на Astra.IDE, ссылки.

Риск и ссылки взяты из исследования Astra.IDE (РегЛаб, ПЛК REGUL) от 16.10.2026: факты F01–F93,
риски R1–R23, чек-лист «проверить вручную» (A1–J3; его продолжение — раздел 9
docs/migration_checklist.md, нумерация та же). Здесь хранятся только те факты, риски и пункты
чек-листа, на которые ссылается отчёт, — с кратким пересказом и первоисточником, чтобы
docs/inventory.md читался без исследования.

Списки имён библиотек Standard, Standard64 и Util сняты с установленного CODESYS 3.5.17.30
(файлы browsercache библиотек версии 3.5.17.0 в Managed Libraries, узлы-POU), методы-утверждения
coUnit — с browsercache coUnit 1.2.0.0. Пространства имён —
из projectinfo тех же библиотек (DefaultNamespace; без него пространство имён совпадает с названием).
Списки зарезервированных слов — из лексеров RuSTy 1.0.6 и iec_checker 0.4 (ссылки ниже).
"""

from __future__ import annotations

from dataclasses import dataclass

# ---------------------------------------------------------------------------
# Шкала риска
# ---------------------------------------------------------------------------

RISK_HIGH = "высокий"
RISK_MEDIUM = "средний"
RISK_LOW = "низкий"
RISK_NONE = "нет"
RISK_ORDER = {RISK_HIGH: 3, RISK_MEDIUM: 2, RISK_LOW: 1, RISK_NONE: 0}

RISK_SCALE: tuple[tuple[str, str], ...] = (
    (
        RISK_HIGH,
        "у вендора не подтверждено, а при отказе нужна переделка структуры кода; или известное "
        "ограничение REGUL, которое требует правки кода",
    ),
    (
        RISK_MEDIUM,
        "у вендора не описано, но есть в базе CODESYS 3.5.17; проверить пробной компиляцией (пункт "
        "чек-листа), при отказе правка локальная",
    ),
    (RISK_LOW, "подтверждено документацией вендора; правки не ожидаются"),
    (RISK_NONE, "базовый МЭК 61131-3 или к Astra.IDE не относится"),
)

TARGET = "Astra.IDE 1.7.2.x (РегЛаб), ПЛК REGUL R500/R400, рантайм REGULRTS"
RESEARCH = (
    "исследование Astra.IDE от 16.10.2026 (факты F01–F93, риски R1–R23, чек-лист A1–J3; продолжение "
    "чек-листа — раздел 9 migration_checklist.md)"
)

# ---------------------------------------------------------------------------
# Группы и возможности
# ---------------------------------------------------------------------------

GROUPS: tuple[tuple[str, str], ...] = (
    ("oop", "ООП"),
    ("pragma", "Прагмы и атрибуты"),
    ("lib", "Библиотеки и пространства имён"),
    ("type", "Типы данных"),
    ("construct", "Конструкции языка"),
    ("retain", "RETAIN и PERSISTENT"),
    ("io", "Привязка к вводу-выводу"),
    ("task", "Задачи"),
    ("ident", "Идентификаторы"),
)


@dataclass(frozen=True)
class Feature:
    """Возможность CODESYS: где искать, насколько рискованна на Astra.IDE и что делать."""

    id: str
    group: str
    title: str
    unit: str
    risk: str
    refs: tuple[str, ...]
    action: str


def _f(fid: str, group: str, title: str, unit: str, risk: str, refs: tuple[str, ...], action: str) -> Feature:
    return Feature(fid, group, title, unit, risk, refs, action)


_FEATURES: tuple[Feature, ...] = (
    # --- ООП ---
    _f(
        "oop.interface",
        "oop",
        "Интерфейсы (`INTERFACE`)",
        "объект",
        RISK_LOW,
        ("F19", "F20", "B3"),
        "Переносить как есть; импорт интерфейсов через PLCopenXML проверить (B3)",
    ),
    _f(
        "oop.interface_extends",
        "oop",
        "Наследование интерфейсов (`INTERFACE … EXTENDS`)",
        "объект",
        RISK_MEDIUM,
        ("F23", "C4"),
        "Проверить пробной компиляцией; при отказе — плоские интерфейсы с повтором методов",
    ),
    _f(
        "oop.implements",
        "oop",
        "Реализация интерфейсов (`IMPLEMENTS`)",
        "POU",
        RISK_LOW,
        ("F20", "F21"),
        "Переносить как есть",
    ),
    _f(
        "oop.extends_fb",
        "oop",
        "Наследование ФБ (`FUNCTION_BLOCK … EXTENDS`)",
        "ФБ",
        RISK_HIGH,
        ("F23", "R15", "C1"),
        "Первым делом — пробный импорт иерархии; при отказе — композиция и интерфейсы, правки `// PORT:`",
    ),
    _f(
        "oop.super",
        "oop",
        "Вызов базовой реализации (`SUPER^`)",
        "вхожд.",
        RISK_HIGH,
        ("F23", "R15", "C1"),
        "Вместе с `EXTENDS`; при композиции — явный вызов вложенного экземпляра",
    ),
    _f(
        "oop.this",
        "oop",
        "`THIS^`",
        "вхожд.",
        RISK_MEDIUM,
        ("F23", "C2"),
        "Проверить компиляцией; при отказе — обращение без `THIS^`",
    ),
    _f(
        "oop.abstract",
        "oop",
        "`ABSTRACT` (ФБ, метод, свойство)",
        "член",
        RISK_MEDIUM,
        ("F23", "R15", "C2"),
        "При отказе — интерфейс вместо абстрактного ФБ",
    ),
    _f(
        "oop.final",
        "oop",
        "`FINAL`",
        "член",
        RISK_MEDIUM,
        ("F23", "C2"),
        "При отказе — убрать модификатор (поведение не меняется)",
    ),
    _f(
        "oop.method",
        "oop",
        "Методы ФБ и программ (`METHOD`)",
        "метод",
        RISK_LOW,
        ("F19", "F21", "F22"),
        "Переносить как есть",
    ),
    _f("oop.method_itf", "oop", "Методы интерфейсов", "метод", RISK_LOW, ("F20",), "Переносить как есть"),
    _f("oop.access_public", "oop", "Спецификатор `PUBLIC`", "член", RISK_LOW, ("F21",), "Переносить как есть"),
    _f(
        "oop.access_default",
        "oop",
        "Метод или свойство без спецификатора (по умолчанию `PUBLIC`)",
        "член",
        RISK_LOW,
        ("F21",),
        "Переносить как есть",
    ),
    _f(
        "oop.access_private",
        "oop",
        "Спецификатор `PRIVATE`",
        "член",
        RISK_MEDIUM,
        ("F23", "C3"),
        "Проверить компиляцией; при отказе — убрать спецификатор (доступ станет `PUBLIC`, поведение то же)",
    ),
    _f(
        "oop.access_protected",
        "oop",
        "Спецификатор `PROTECTED`",
        "член",
        RISK_MEDIUM,
        ("F23", "C3"),
        "Как `PRIVATE`; зависит от `EXTENDS`",
    ),
    _f("oop.access_internal", "oop", "Спецификатор `INTERNAL`", "член", RISK_MEDIUM, ("F23", "C3"), "Как `PRIVATE`"),
    _f(
        "oop.property",
        "oop",
        "Свойства ФБ (`PROPERTY`)",
        "свойство",
        RISK_MEDIUM,
        ("F22", "C3"),
        "У вендора свойства показаны только у библиотечных ФБ; проверить в пользовательском ФБ (C3), "
        "при отказе — методы `GetX`/`SetX`",
    ),
    _f("oop.property_get", "oop", "Аксессор `Get`", "аксессор", RISK_MEDIUM, ("F22", "C3"), "Вместе со свойством"),
    _f("oop.property_set", "oop", "Аксессор `Set`", "аксессор", RISK_MEDIUM, ("F22", "C3"), "Вместе со свойством"),
    _f(
        "oop.property_itf",
        "oop",
        "Свойства интерфейсов",
        "свойство",
        RISK_MEDIUM,
        ("F22", "C3"),
        "Вместе со свойствами ФБ",
    ),
    _f("oop.fb_init", "oop", "Конструктор `FB_init`", "метод", RISK_LOW, ("F22",), "Переносить как есть"),
    _f(
        "oop.fb_exit",
        "oop",
        "`FB_exit`, `FB_reinit`",
        "метод",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией и поведением при онлайн-изменении",
    ),
    _f(
        "oop.itf_var",
        "oop",
        "Переменные интерфейсного типа",
        "перем.",
        RISK_MEDIUM,
        ("F85", "R8", "G4"),
        "В коде — как есть; в символьную конфигурацию OPC UA не публиковать (проверить G4)",
    ),
    _f(
        "oop.queryinterface",
        "oop",
        "`__QUERYINTERFACE`, `__QUERYPOINTER`",
        "вхожд.",
        RISK_MEDIUM,
        ("F23", "C4"),
        "Проверить компиляцией",
    ),
    # --- Прагмы (атрибуты — см. ATTRIBUTES) ---
    _f(
        "pragma.conditional",
        "pragma",
        "Условная компиляция `{IF …}`",
        "вхожд.",
        RISK_MEDIUM,
        ("F29", "C6"),
        "Проверить компиляцией",
    ),
    _f(
        "pragma.message",
        "pragma",
        "Прагмы сообщений `{warning}`, `{error}`, `{info}`",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    _f(
        "pragma.other",
        "pragma",
        "Прочие прагмы",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    # --- Библиотеки ---
    _f(
        "lib.standard",
        "lib",
        "Standard (таймеры, триггеры, счётчики, строки)",
        "вхожд.",
        RISK_LOW,
        ("F50",),
        "Переносить как есть",
    ),
    _f(
        "lib.standard64",
        "lib",
        "Standard64 (`LTON`/`LTOF`/`LTP`, `LCTU`…, функции `WSTRING`)",
        "вхожд.",
        RISK_LOW,
        ("F35", "F50", "C11"),
        "Библиотека есть; LTIME-таймеры проверить (C11)",
    ),
    _f("lib.util", "lib", "Util", "вхожд.", RISK_LOW, ("F50",), "Переносить как есть"),
    _f(
        "lib.systime",
        "lib",
        "SysTime, SysTimeCore, SysTimeRtc",
        "вхожд.",
        RISK_LOW,
        ("F52", "R20"),
        "Есть; источник времени на REGUL — `FB_TimeSource_Regul` (R20)",
    ),
    _f(
        "lib.sysfile",
        "lib",
        "SysFile, SysDir",
        "вхожд.",
        RISK_LOW,
        ("F51",),
        "Есть; операции синхронные — вызывать из задачи с низким приоритетом",
    ),
    _f(
        "lib.caa_file",
        "lib",
        "CAA File (`FILE.*`)",
        "вхожд.",
        RISK_MEDIUM,
        ("F53", "R19", "C10"),
        "Проверить на ВПЛК (C10); иначе SysFile в задаче с низким приоритетом",
    ),
    _f(
        "lib.caa_other",
        "lib",
        "CAA Memory (`MEM`), CAA SerialCom (`COM`)",
        "вхожд.",
        RISK_LOW,
        ("F04",),
        "Плейсхолдеры есть в описании устройства",
    ),
    _f(
        "lib.device",
        "lib",
        "Библиотеки устройства (`IoStandard`, CAA Device Diagnosis `DED`)",
        "вхожд.",
        RISK_MEDIUM,
        ("R1",),
        "Дерево устройств REGUL другое: обращения к устройству пересобрать",
    ),
    _f(
        "lib.runtime",
        "lib",
        "Компоненты рантайма (CmpLog, CmpApp, CmpIecTask, SysMem, SysCom, SysSocket)",
        "вхожд.",
        RISK_LOW,
        ("F04",),
        "Плейсхолдеры есть в описании устройства",
    ),
    _f(
        "lib.counit_deps",
        "lib",
        "IECStringUtils, Base Interfaces, Breakpoint Logging",
        "вхожд.",
        RISK_MEDIUM,
        ("F73", "A4"),
        "Наличие в репозитории Astra.IDE не подтверждено (A4)",
    ),
    _f(
        "lib.counit",
        "lib",
        "coUnit (юнит-тесты: `coUnit.*`, методы `Assert*`)",
        "вхожд.",
        RISK_HIGH,
        ("F73", "R18", "H2", "H3"),
        "Сначала собрать тестовый проект с coUnit (H2); при отказе тесты логики — в CODESYS 3.5.17.30, на "
        "REGUL — интеграционные сценарии и PsUnittest",
    ),
    _f(
        "lib.pl",
        "lib",
        "Своя библиотека `PL` (plc-process-lib)",
        "вхожд.",
        RISK_LOW,
        ("F78", "F79"),
        "Переносится вместе с кодом; пространство имён `PL` не пересекается с вендорскими `Ps*`",
    ),
    # --- Типы данных ---
    _f(
        "type.ltime",
        "type",
        "Тип `LTIME`",
        "вхожд.",
        RISK_MEDIUM,
        ("F30", "F34", "C11"),
        "Тип есть (структура OPC UA `ua_var_ltime`); арифметику проверить (C11); в OPC UA — как `ULINT` нс",
    ),
    _f(
        "type.ltime_literal",
        "type",
        "Литералы `LTIME#`, `LT#`",
        "вхожд.",
        RISK_MEDIUM,
        ("F34", "C11"),
        "Проверить компиляцией (C11)",
    ),
    _f(
        "type.ltime_conv",
        "type",
        "Преобразования `*_TO_LTIME`, `LTIME_TO_*`",
        "вхожд.",
        RISK_MEDIUM,
        ("F34", "C11"),
        "Проверить компиляцией (C11)",
    ),
    _f("type.int64", "type", "`LINT`, `ULINT`, `LWORD`", "вхожд.", RISK_LOW, ("F30",), "Переносить как есть"),
    _f(
        "type.wstring",
        "type",
        '`WSTRING` и литералы `"…"`',
        "вхожд.",
        RISK_LOW,
        ("F30", "F35", "R23"),
        "Есть; для кириллицы в визуализации — «Использовать строки Unicode»",
    ),
    _f("type.ldate", "type", "`LDATE`, `LTOD`, `LDT`", "вхожд.", RISK_MEDIUM, ("F34",), "Проверить компиляцией"),
    _f(
        "type.reference",
        "type",
        "`REFERENCE TO`",
        "вхожд.",
        RISK_MEDIUM,
        ("F31", "F85", "F28", "R8"),
        "В коде есть; в символьной конфигурации OPC UA запрещены с 1.7.2.5, при резервировании не "
        "синхронизируются — публиковать через плоский фасад",
    ),
    _f(
        "type.pointer", "type", "`POINTER TO`", "вхожд.", RISK_MEDIUM, ("F31", "F85", "F28", "R8"), "Как `REFERENCE TO`"
    ),
    _f("type.struct", "type", "Структуры (`STRUCT`)", "DUT", RISK_LOW, ("F32",), "Переносить как есть"),
    _f(
        "type.struct_extends",
        "type",
        "Наследование структур (`STRUCT … EXTENDS`)",
        "DUT",
        RISK_MEDIUM,
        ("F34", "R17", "C8"),
        "Проверить; при отказе — вложенная структура",
    ),
    _f(
        "type.union",
        "type",
        "Объединения (`UNION`)",
        "DUT",
        RISK_LOW,
        ("F32", "C8"),
        "Есть; `UNION` в составе структуры проверить (C8)",
    ),
    _f("type.enum", "type", "Перечисления", "DUT", RISK_LOW, ("F33",), "Переносить как есть"),
    _f(
        "type.enum_base",
        "type",
        "Перечисления с базовым типом (`(…) INT`)",
        "DUT",
        RISK_MEDIUM,
        ("F34", "R17", "C7"),
        "Проверить (C7); при отказе — без базового типа, с явными значениями",
    ),
    _f("type.alias", "type", "Псевдонимы типов", "DUT", RISK_LOW, ("F32",), "Переносить как есть"),
    _f(
        "type.subrange",
        "type",
        "Поддиапазоны (`INT(0..100)`)",
        "вхожд.",
        RISK_LOW,
        ("F36",),
        "Есть (неявные проверки `CheckRange*`)",
    ),
    _f(
        "type.array_varlen",
        "type",
        "Массивы переменной длины `ARRAY[*]`",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    _f(
        "type.any",
        "type",
        "Обобщённые типы `ANY`, `ANY_*`",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    _f("type.bit", "type", "Тип `BIT`", "вхожд.", RISK_LOW, ("F32",), "Есть в структурах и ФБ, в массивах — нет"),
    _f(
        "type.xint",
        "type",
        "`__XINT`, `__UXINT`, `__XWORD`",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    # --- Конструкции ---
    _f(
        "construct.var_in_out",
        "construct",
        "`VAR_IN_OUT`",
        "секция",
        RISK_LOW,
        ("C13",),
        "Базовый МЭК; с массивами и строками проверить (C13)",
    ),
    _f(
        "construct.var_in_out_const",
        "construct",
        "`VAR_IN_OUT CONSTANT`",
        "секция",
        RISK_MEDIUM,
        ("C13",),
        "Проверить (C13); при отказе — `VAR_IN_OUT` без `CONSTANT`",
    ),
    _f("construct.var_stat", "construct", "`VAR_STAT`", "секция", RISK_LOW, ("F33",), "Переносить как есть"),
    _f(
        "construct.var_inst",
        "construct",
        "`VAR_INST`",
        "секция",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    _f("construct.var_temp", "construct", "`VAR_TEMP`", "секция", RISK_NONE, (), "Базовый МЭК"),
    _f("construct.var_external", "construct", "`VAR_EXTERNAL`", "секция", RISK_NONE, (), "Базовый МЭК"),
    _f(
        "construct.var_constant",
        "construct",
        "Локальные константы (`VAR CONSTANT`)",
        "секция",
        RISK_NONE,
        (),
        "Базовый МЭК",
    ),
    _f(
        "construct.gvl_constant",
        "construct",
        "`VAR_GLOBAL CONSTANT`",
        "секция",
        RISK_LOW,
        ("F47",),
        "Переносить как есть",
    ),
    _f(
        "construct.gvl_mixed",
        "construct",
        "GVL с `VAR_GLOBAL` и `VAR_GLOBAL CONSTANT` в одном объекте",
        "GVL",
        RISK_MEDIUM,
        ("F47",),
        "Для экспорта PLCopenXML держать в разных списках",
    ),
    _f(
        "construct.ltime_op",
        "construct",
        "Оператор `LTIME()` (монотонное время)",
        "вхожд.",
        RISK_MEDIUM,
        ("F52", "R20", "C11"),
        "Проверить на REGUL; запасной путь — `FB_TimeSource_Regul` на `PsTimeGetUtcTimeNs` или `SysTimeRtc`",
    ),
    _f(
        "construct.time_op",
        "construct",
        "Оператор `TIME()`",
        "вхожд.",
        RISK_MEDIUM,
        ("R20",),
        "Проверить на REGUL; на ВПЛК время не жёсткое",
    ),
    _f(
        "construct.sizeof",
        "construct",
        "`SIZEOF`",
        "вхожд.",
        RISK_LOW,
        ("§2.9",),
        "Есть в примерах вендора (`ModbusUserRequest2`)",
    ),
    _f("construct.adr", "construct", "`ADR`", "вхожд.", RISK_LOW, ("F31", "§2.9"), "Есть в примерах вендора"),
    _f("construct.bitadr", "construct", "`BITADR`", "вхожд.", RISK_MEDIUM, (), "В исследовании нет"),
    _f(
        "construct.deref",
        "construct",
        "Разыменование `^`",
        "вхожд.",
        RISK_LOW,
        ("F31",),
        "Есть; указатели не публиковать в OPC UA",
    ),
    _f(
        "construct.ref_assign",
        "construct",
        "Присваивание ссылки `REF=`",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    _f(
        "construct.new",
        "construct",
        "`__NEW`, `__DELETE`",
        "вхожд.",
        RISK_MEDIUM,
        ("F37", "C12"),
        "Проверить настройки динамической памяти (C12)",
    ),
    _f(
        "construct.isvalidref",
        "construct",
        "`__ISVALIDREF`",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    _f("construct.try", "construct", "`__TRY` … `__ENDTRY`", "блок", RISK_LOW, ("F36",), "Есть"),
    _f("construct.system", "construct", "`__SYSTEM.*`", "вхожд.", RISK_MEDIUM, (), "В исследовании нет"),
    _f(
        "construct.dunder_other",
        "construct",
        "Прочие операторы `__*`",
        "вхожд.",
        RISK_MEDIUM,
        (),
        "В исследовании нет: проверить компиляцией",
    ),
    _f(
        "construct.check_pou",
        "construct",
        "POU неявных проверок (`CheckBounds`, `CheckDivInt`…)",
        "объект",
        RISK_LOW,
        ("F36",),
        "Есть",
    ),
    # --- RETAIN и PERSISTENT ---
    _f(
        "retain.retain",
        "retain",
        "`RETAIN`",
        "перем.",
        RISK_LOW,
        ("F38", "F39", "F40", "R12"),
        "Семантика как в CODESYS; RETAIN сбрасываются при загрузке приложения — `saveretain` перед ней",
    ),
    _f(
        "retain.persistent",
        "retain",
        "`PERSISTENT`",
        "перем.",
        RISK_LOW,
        ("F38", "F40", "F41", "R10"),
        "Есть; запись синхронизируется при каждом изменении — писать по событию или с периодом",
    ),
    _f(
        "retain.pvl",
        "retain",
        "Объект Persistent Variables (`*.pvl.st`)",
        "объект",
        RISK_MEDIUM,
        ("F41", "R11", "D1"),
        "Создать «Persistent-переменные…» вручную или импортом PLCopenXML",
    ),
    _f("retain.non_retain", "retain", "`NON_RETAIN`", "перем.", RISK_NONE, (), "Базовый МЭК"),
    # --- Ввод-вывод ---
    _f(
        "io.at_wildcard",
        "io",
        "`AT %I*` / `%Q*` (адрес назначается в дереве устройств)",
        "перем.",
        RISK_LOW,
        ("F58", "R1"),
        "Привязать в «Соотнесении входов/выходов» модулей REGUL",
    ),
    _f(
        "io.at_fixed",
        "io",
        "`AT` с фиксированным адресом (`%IX0.0`, `%QW2`)",
        "перем.",
        RISK_HIGH,
        ("F58", "R1"),
        "Раскладка адресов REGUL другая: перейти на `%I*`/`%Q*` и привязку в дереве устройств",
    ),
    _f(
        "io.at_memory",
        "io",
        "`AT %M…`",
        "перем.",
        RISK_MEDIUM,
        ("F60",),
        "Проверить карту M-памяти (у вендора — для Modbus Slave)",
    ),
    _f(
        "io.direct",
        "io",
        "Прямые адреса в коде",
        "вхожд.",
        RISK_HIGH,
        ("R1",),
        "Заменить переменными с привязкой в дереве устройств",
    ),
    # --- Задачи ---
    _f(
        "task.config",
        "task",
        "Задачи из `tools/codesys/config.json`",
        "задача",
        RISK_MEDIUM,
        ("F04", "R13", "J1"),
        "Переназначить приоритеты: на REGUL пользовательские 2–15 (ЦП I/III) или 5–15 (ЦП II)",
    ),
    # --- Идентификаторы ---
    _f(
        "ident.rusty",
        "ident",
        "Зарезервированы в RuSTy 1.0.6",
        "имя",
        RISK_NONE,
        ("F01",),
        "В Astra.IDE (база CODESYS 3.5.17) не мешают; для RuSTy — переименовать или понижение сборки",
    ),
    _f(
        "ident.iec_checker",
        "ident",
        "Зарезервированы в iec_checker 0.4",
        "имя",
        RISK_NONE,
        ("F01",),
        "В Astra.IDE не мешают; для iec_checker — переименовать или понижение сборки",
    ),
    _f(
        "ident.vendor_prefix",
        "ident",
        "Имена объектов с префиксом `Ps` (библиотеки вендора)",
        "объект",
        RISK_MEDIUM,
        ("F54", "F79"),
        "Переименовать: префикс `Ps` занят библиотеками РегЛаб",
    ),
)

FEATURES: dict[str, Feature] = {f.id: f for f in _FEATURES}

# ---------------------------------------------------------------------------
# Атрибуты {attribute '...'}
# ---------------------------------------------------------------------------

# имя атрибута (в нижнем регистре) -> (риск, ссылки, что делать)
ATTRIBUTES: dict[str, tuple[str, tuple[str, ...], str]] = {
    "qualified_only": (RISK_LOW, ("F25",), "Есть"),
    "symbol": (RISK_LOW, ("F26", "F85"), "Есть; ссылки и указатели в символьной конфигурации запрещены"),
    "pack_mode": (
        RISK_HIGH,
        ("F27", "R14", "C9"),
        "На ЦП II типа (ARM) отключать выравнивание нельзя — разбирать регистры функциями",
    ),
    "strict": (
        RISK_MEDIUM,
        ("F29", "R16", "C5"),
        "Проверить, что неквалифицированное обращение даёт ошибку; иначе следить вручную",
    ),
    "call_after_init": (RISK_MEDIUM, ("F29", "R16", "C6"), "При отказе — явная инициализация в первом цикле"),
    "hide": (RISK_MEDIUM, ("F29", "C6"), "Проверить компиляцией"),
    "no_check": (RISK_MEDIUM, ("F29", "C6"), "Проверить компиляцией"),
    "init_namespace": (RISK_MEDIUM, ("F29", "C6"), "Проверить компиляцией"),
    "monitoring": (RISK_MEDIUM, ("F29", "C6"), "Проверить компиляцией"),
    "linkalways": (
        RISK_MEDIUM,
        ("C14",),
        "В документации РегЛаб нет; проверить, что GVL без ссылок из кода попадает в приложение (C14)",
    ),
    "ps.add_redundancy": (RISK_NONE, ("F28",), "Атрибут вендора"),
}
ATTRIBUTE_DEFAULT: tuple[str, tuple[str, ...], str] = (
    RISK_MEDIUM,
    (),
    "В исследовании нет: проверить компиляцией (CODESYS принимает и неизвестные атрибуты — проверять и действие)",
)


def attribute_feature(name: str) -> Feature:
    """Возможность «атрибут name» (имя без кавычек, без учёта регистра)."""
    key = name.lower()
    risk, refs, action = ATTRIBUTES.get(key, ATTRIBUTE_DEFAULT)
    return Feature("attr." + key, "pragma", f"`{{attribute '{key}'}}`", "вхожд.", risk, refs, action)


def feature(fid: str) -> Feature:
    """Возможность по идентификатору (в том числе атрибуты attr.<имя>)."""
    if fid.startswith("attr."):
        return attribute_feature(fid[len("attr.") :])
    return FEATURES[fid]


# ---------------------------------------------------------------------------
# Пространства имён и имена библиотек
# ---------------------------------------------------------------------------

# пространство имён (в верхнем регистре) -> возможность
NAMESPACES: dict[str, str] = {
    "STANDARD": "lib.standard",
    "STANDARD64": "lib.standard64",
    "UTIL": "lib.util",
    "SYSTIME": "lib.systime",
    "SYSTIMECORE": "lib.systime",
    "SYSTIMERTC": "lib.systime",
    "SYSFILE": "lib.sysfile",
    "SYSFILEASYNC": "lib.sysfile",
    "SYSDIR": "lib.sysfile",
    "SYSDIRASYNC": "lib.sysfile",
    "FILE": "lib.caa_file",
    "MEM": "lib.caa_other",
    "COM": "lib.caa_other",
    "IOSTANDARD": "lib.device",
    "DED": "lib.device",
    "CMPLOG": "lib.runtime",
    "CMPAPP": "lib.runtime",
    "CMPIECTASK": "lib.runtime",
    "SYSMEM": "lib.runtime",
    "SYSCOM": "lib.runtime",
    "SYSSOCKET": "lib.runtime",
    "IECSTRINGUTILS": "lib.counit_deps",
    "IBASELIBRARY": "lib.counit_deps",
    "BPLOG": "lib.counit_deps",
    "COUNIT": "lib.counit",
    "PL": "lib.pl",
}

# Префиксы функций системных библиотек, которые вызывают без пространства имён
SYSTEM_FUNCTION_PREFIXES: tuple[tuple[str, str], ...] = (
    ("SYSTIME", "lib.systime"),
    ("SYSFILE", "lib.sysfile"),
    ("SYSDIR", "lib.sysfile"),
    ("SYSMEM", "lib.runtime"),
    ("SYSCOM", "lib.runtime"),
    ("SYSSOCK", "lib.runtime"),
)


def _words(text: str) -> frozenset[str]:
    """Множество слов текста в верхнем регистре (имена CODESYS не различают регистр)."""
    return frozenset(text.upper().split())


# POU библиотек CODESYS 3.5.17.0 (browsercache установленного CODESYS 3.5.17.30)
STANDARD_POUS = _words(
    "CONCAT CTD CTU CTUD DELETE FIND F_TRIG INSERT LEFT LEN MID REPLACE RIGHT RS RTC R_TRIG SR TOF TON TP"
)
STANDARD64_POUS = _words(
    "AtomicReadLInt AtomicReadLReal AtomicReadLTime AtomicReadLWord AtomicReadULInt AtomicWriteLInt "
    "AtomicWriteLReal AtomicWriteLTime AtomicWriteLWord AtomicWriteULInt LCTD LCTU LCTUD LTOF LTON LTP "
    "WCONCAT WDELETE WFIND WINSERT WLEFT WLEN WMID WREPLACE WRIGHT"
)
UTIL_POUS = _words(
    "BASE64 BCD_TO_BYTE BCD_TO_DWORD BCD_TO_INT BCD_TO_WORD BIT_AS_BYTE BIT_AS_DWORD BIT_AS_WORD BLINK "
    "BYTE_AS_BIT BYTE_TO_BCD BYTE_TO_GRAY BYTE_TO_HEXinASCII CHARCURVE CombineDateTime ConvertDateTime "
    "DERIVATIVE DWORD_AS_BIT DWORD_TO_BCD DWORD_TO_GRAY DateTimeFromWeek DateTimeProvider DayOfWeek EXTRACT "
    "ExtractYearMonthDay FREQ_MEASURE GEN GETBIT GRAY_TO_BYTE GRAY_TO_DWORD GRAY_TO_WORD GetDateTime "
    "GetLibVersion GetLibVersionNumber GetLocalDateTime GetTimeStampsDifference HEXinASCII_TO_BYTE "
    "HYSTERESIS INTEGRAL INT_TO_BCD IsLeapYear IsLibReleased JoinDateTime JoinYearMonthDay LIMITALARM "
    "LIN_TRAFO LastWeekOfYear LeapYears LocalDateTime PACK PD PID PID_FIXCYCLE PUTBIT RAMP_INT RAMP_REAL "
    "SETBIT STATISTICS_INT STATISTICS_REAL SWITCHBIT SeparateDateTime SplitDateTime TimerSwitch UNPACK VARIANCE "
    "WORD_AS_BIT WORD_AS_STRING WORD_TO_BCD WORD_TO_GRAY WeekOfYear"
)
LIBRARY_POUS: dict[str, str] = {
    **dict.fromkeys(UTIL_POUS, "lib.util"),
    **dict.fromkeys(STANDARD64_POUS, "lib.standard64"),
    **dict.fromkeys(STANDARD_POUS, "lib.standard"),
}

# Методы-утверждения coUnit 1.2.0.0 (FB_TestSuite): наборы тестов вызывают их без пространства имён
COUNIT_ASSERTS = _words(
    "AssertArray2dEquals_LREAL AssertArray2dEquals_REAL AssertArray3dEquals_LREAL AssertArray3dEquals_REAL "
    "AssertArrayEquals_BOOL AssertArrayEquals_BYTE AssertArrayEquals_DINT AssertArrayEquals_DWORD "
    "AssertArrayEquals_INT AssertArrayEquals_LINT AssertArrayEquals_LREAL AssertArrayEquals_LWORD "
    "AssertArrayEquals_REAL AssertArrayEquals_SINT AssertArrayEquals_UDINT AssertArrayEquals_UINT "
    "AssertArrayEquals_ULINT AssertArrayEquals_USINT AssertArrayEquals_WORD AssertEquals AssertEquals_BOOL "
    "AssertEquals_BYTE AssertEquals_DATE AssertEquals_DATE_AND_TIME AssertEquals_DINT AssertEquals_DWORD "
    "AssertEquals_INT AssertEquals_LINT AssertEquals_LREAL AssertEquals_LTIME AssertEquals_LWORD AssertEquals_REAL "
    "AssertEquals_SINT AssertEquals_STRING AssertEquals_TIME AssertEquals_TIME_OF_DAY AssertEquals_UDINT "
    "AssertEquals_UINT AssertEquals_ULINT AssertEquals_USINT AssertEquals_WORD AssertEquals_WSTRING AssertFalse "
    "AssertTrue"
)
LIBRARY_POUS.update(dict.fromkeys(COUNIT_ASSERTS, "lib.counit"))

# Неявные проверки CODESYS (POU с этими именами компилятор вызывает сам)
CHECK_POUS = _words(
    "CheckBounds CheckDivInt CheckDivLint CheckDivReal CheckDivLReal CheckRangeSigned CheckRangeUnsigned "
    "CheckLRangeSigned CheckLRangeUnsigned CheckPointer"
)

# ---------------------------------------------------------------------------
# Зарезервированные слова других сред МЭК
# ---------------------------------------------------------------------------

RUSTY_SOURCE = (
    "RuSTy 1.0.6, лексер compiler/plc_lexer/src/lexer/tokens.rs",
    "https://github.com/PLC-lang/rusty/blob/v1.0.6/compiler/plc_lexer/src/lexer/tokens.rs",
)
IEC_CHECKER_SOURCE = (
    "iec_checker 0.4, лексер src/parser/lexer.mll (таблица ключевых слов и управляющие слова)",
    "https://github.com/iec-checker/iec-checker/blob/v0.4/src/parser/lexer.mll",
)

# Ключевые слова RuSTy (без учёта регистра); составное «REFERENCE TO» отдельным словом не считается,
# PROPERTY_GET/PROPERTY_SET — мягкие ключевые слова, вне свойств допустимы как имена.
RUSTY_KEYWORDS = _words(
    """
    ABSTRACT ACTION ACTIONS AND AND_THEN ARRAY AT BY CASE CLASS CONSTANT CONTINUE DO ELSE ELSIF
    ENDACTION ENDACTIONS ENDCASE ENDCLASS ENDFOR ENDFUNCTION ENDFUNCTIONBLOCK ENDIF ENDINTERFACE ENDMETHOD
    ENDPROGRAM ENDPROPERTY ENDREPEAT ENDSTRUCT ENDTYPE ENDVAR ENDWHILE END_ACTION END_ACTIONS END_CASE
    END_CLASS END_FOR END_FUNCTION END_FUNCTION_BLOCK END_IF END_INTERFACE END_METHOD END_PROGRAM
    END_PROPERTY END_REPEAT END_STRUCT END_TYPE END_VAR END_WHILE EXIT EXTENDS FALSE FINAL FOR FUNCTION
    FUNCTIONBLOCK FUNCTION_BLOCK IF IMPLEMENTS INTERFACE INTERNAL METHOD MOD NONRETAIN NON_RETAIN NOT NULL
    OF OR OR_ELSE OVERRIDE POINTER PRIVATE PROGRAM PROTECTED PUBLIC REFTO REF_TO REPEAT RETAIN RETURN STRING
    STRUCT SUPER THEN THIS TO TRUE TYPE UNTIL VAR VARGLOBAL VARINOUT VARINPUT VAROUTPUT VARTEMP VAR_CONFIG
    VAR_EXTERNAL VAR_GLOBAL VAR_INPUT VAR_IN_OUT VAR_OUTPUT VAR_TEMP WHILE WSTRING XOR __FPOINTER
    """
)

# Ключевые слова iec_checker: таблица без учёта регистра и управляющие слова (только в верхнем регистре)
IEC_CHECKER_KEYWORDS = _words(
    """
    ABSTRACT AND ANY ANY_BIT ANY_DATE ANY_DERIVED ANY_ELEMENTARY ANY_INT ANY_MAGNITUDE ANY_NUM ANY_REAL
    ANY_STRING ARRAY AT BOOL BYTE CHAR CLASS CONFIGURATION CONSTANT DATE DATE_AND_TIME DINT DT DWORD
    END_CLASS END_CONFIGURATION END_FUNCTION END_FUNCTION_BLOCK END_INTERFACE END_METHOD END_PROGRAM
    END_RESOURCE END_STRUCT END_TYPE END_VAR EQU EXTENDS FINAL FUNCTION FUNCTION_BLOCK IMPLEMENTS INT
    INTERFACE INTERNAL INTERVAL LDATE LDATE_AND_TIME LDT LINT LREAL LTIME LTIME_OF_DAY LTOD LWORD METHOD MOD
    NON_RETAIN NOT NULL ON OR OVERLAP OVERRIDE PRIORITY PRIVATE PROGRAM PROTECTED PUBLIC READ_ONLY READ_WRITE
    REAL REF REF_TO RESOURCE RETAIN SINGLE SINT STRING STRUCT TASK TIME TIME_OF_DAY TOD TYPE UDINT UINT ULINT
    USINT VAR VAR_ACCESS VAR_CONFIG VAR_EXTERNAL VAR_GLOBAL VAR_INPUT VAR_IN_OUT VAR_OUTPUT VAR_TEMP WCHAR
    WITH WORD WSTRING XOR
    BY CASE CONTINUE DO ELSE ELSIF END_CASE END_FOR END_IF END_REPEAT END_WHILE EXIT FOR IF OF REPEAT RETURN
    THEN TO UNTIL WHILE
    """
)

RESERVED_SETS: tuple[tuple[str, str, frozenset[str], tuple[str, str]], ...] = (
    ("ident.rusty", "RuSTy 1.0.6", RUSTY_KEYWORDS, RUSTY_SOURCE),
    ("ident.iec_checker", "iec_checker 0.4", IEC_CHECKER_KEYWORDS, IEC_CHECKER_SOURCE),
)

# ---------------------------------------------------------------------------
# Ссылки: факты, риски, пункты чек-листа исследования
# ---------------------------------------------------------------------------

_DPA302 = (
    "https://reglab.ru/upload/iblock/86e/aqrzbeuk0bjd3jdn1au63e8i2r5d63wk/Astra-IDE-User-Guide-_DPA_302_v2_20_rus.pdf"
)
_DPA302_1 = (
    "https://reglab.ru/upload/iblock/c63/bxjpd31viamzx3b4i0nj0zthy4xq1sg1/Modbus-User-Guide-DPA_302-1_v1.7_rus.pdf"
)
_DPA302_2 = (
    "https://reglab.ru/upload/iblock/a6f/cu6npbpdnappv49sj4a0us8zujoroxp3/"
    "Nastroyka-IEC_104_101-User-Guide_DPA_302_2_v2.11_rus.pdf"
)
_DPA302_4 = "https://reglab.ru/upload/iblock/28f/tmu37n4jz4w5oxepmx0431vb5q5yo6xw/Redundancy-User-Guide-_DPA_302_4_v2_11_rus.pdf"
_DPA302_6 = (
    "https://reglab.ru/upload/iblock/57b/dvvplmt0qby4duccefw4vyi9j3u59ziu/OPC_UA_User_Guide_DPA_302_6_v1_7_rus.pdf"
)
_PACKAGE = "https://reglab.ru/upload/iblock/0fd/bkk3sngi1qu0kz62c3j1so8iykr78fr6/RegLab_Ltd_Regul_1.7.2.6.package"
_COURSE = "https://reglab.ru/upload/materialy-kursa/"
_SOFT = "https://reglab.ru/soft/"


@dataclass(frozen=True)
class Fact:
    """Факт исследования: краткий пересказ, где сказано, ссылка (пусто — первоисточника нет)."""

    text: str
    where: str
    url: str


FACTS: dict[str, Fact] = {
    "F01": Fact(
        "В выпуске 1.7.0.0 (17.05.2022) Epsilon LD переименована в Astra.IDE, рантайм обновлён до 3.5.17.30 "
        "(CODESYS V3.5 SP17 Patch 3)",
        "reglab.ru/soft, «Релиз Regul 1.7.0.0»",
        _SOFT,
    ),
    "F04": Fact(
        "Описание устройства REGUL R500 71-W совместимо с 3.5.17.*; плейсхолдеры системных библиотек "
        "разрешаются на 3.5.17.0 (SysFile, SysDir, SysTime, SysTimeRtc, CAA File, CAA Memory, CAA SerialCom, "
        "CmpLog, CmpApp, CmpIecTask и др.); задачи: приоритет по умолчанию 2, максимальный 15, до 100 задач",
        "пакет 1.7.2.6, REGUL R500 71-W.devdesc.xml",
        _PACKAGE,
    ),
    "F19": Fact(
        "POU может быть программой, функцией, ФБ, методом, действием, интерфейсом, DUT",
        "DPA-302 v2.20, с. 38, 43",
        _DPA302,
    ),
    "F20": Fact(
        "Пример вендора: ФБ `IMPLEMENTS` трёх интерфейсов с callback-методами и параметрами `POINTER TO`",
        "DPA-302 v2.20, прил. И, с. 309–313",
        _DPA302,
    ),
    "F21": Fact(
        "В примере вендора — `METHOD PUBLIC`, реализация библиотечного интерфейса, свойства у ФБ драйвера",
        "DPA-302.2 v2.11 (IEC 101/104), с. 28, 30",
        _DPA302_2,
    ),
    "F22": Fact(
        "Курс описывает `FB_Init` и методы ФБ; у библиотечных ФБ есть `FB_init` с параметрами и свойство с Get/Set",
        "курс, 5.10; DPA-302 v2.20, с. 388, 397",
        _COURSE + "funktsionalnyj_blok_fb_sin_x.htm",
    ),
    "F23": Fact(
        "`EXTENDS` для ФБ, `SUPER^`, `THIS^`, `ABSTRACT`, `FINAL`, `PRIVATE/PROTECTED/INTERNAL`, наследование "
        "интерфейсов, `__QUERYINTERFACE` в документации вендора не найдены (DPA-302*, курс, форум)",
        "отсутствие в документах; работа в Astra.IDE — проверить вручную",
        "",
    ),
    "F25": Fact(
        "`{attribute 'qualified_only'}` — к переменным GVL обращаются только с именем списка",
        "курс, 5.7",
        _COURSE + "atribut__qualified_only_.htm",
    ),
    "F26": Fact(
        "`{attribute 'symbol' := 'readwrite' | 'read' | 'write' | 'none'}` — публикация в OPC UA; в 1.7.2.6 "
        "исправлено исключение переменных через `'none'`",
        "курс, 12.4; reglab.ru/soft, «Патч 1.7.2.6»",
        _COURSE + "ispolzovanie_atributov.htm",
    ),
    "F27": Fact(
        "`{attribute 'pack_mode'}` управляет выравниванием; на ЦП II типа (ARM) отключать выравнивание нельзя",
        "курс, 5.9",
        _COURSE + "vyravnivanie_pamyati_v_strukturakh.htm",
    ),
    "F28": Fact(
        "Атрибут вендора `ps.add_redundancy`; REFERENCE, POINTER и массивы с ними не резервируются",
        "DPA-302.4 v2.11, с. 46, 57",
        _DPA302_4,
    ),
    "F29": Fact(
        "`'strict'`, `'call_after_init'`, `'hide'`, `'no_check'`, `'init_namespace'`, `'monitoring'` и "
        "`{IF defined(...)}` в документации не найдены",
        "DPA-302 v2.20, с. 43",
        _DPA302,
    ),
    "F30": Fact(
        "В таблицах OPC UA есть `LWORD`, `LINT/ULINT`, `WSTRING` и структура `ua_var_ltime` для `LTIME`",
        "DPA-302.6 v1.7, с. 7–10",
        _DPA302_6,
    ),
    "F31": Fact(
        "`REFERENCE TO` и `POINTER TO` используются в интерфейсах библиотек и примерах вендора",
        "DPA-302 v2.20, с. 311–322; DPA-302.1 v1.7, с. 22",
        _DPA302,
    ),
    "F32": Fact(
        "DUT: структура, перечисление, псевдоним, объединение; `BIT` — в структурах и ФБ, не в массивах",
        "курс, 5.8",
        _COURSE + "strukturnye_tipy.htm",
    ),
    "F33": Fact(
        "Перечисления с явными значениями и `VAR_STAT` поддерживаются (видны в OPC UA)",
        "DPA-302.6 v1.7, с. 12–14",
        _DPA302_6,
    ),
    "F34": Fact(
        "Перечисления с базовым типом, `STRUCT … EXTENDS`, `LDATE/LTOD/LDT`, литералы и арифметика `LTIME` "
        "в документации не описаны",
        "отсутствие в документах; проверить вручную",
        "",
    ),
    "F35": Fact(
        "`STRING` по умолчанию 80 символов; `LEN` из Standard, `WLEN` из Standard64",
        "курс, 5.13",
        _COURSE + "rabota_so_strokovymi_peremennymi.htm",
    ),
    "F36": Fact(
        "Поддержаны `__TRY/__CATCH/__FINALLY/__ENDTRY` и POU неявных проверок (`CheckBounds`, `CheckDiv*`, "
        "`CheckRange*`, `CheckPointer`)",
        "курс, 6.16–6.17",
        _COURSE + "pou_dlya_neyavnykh_proverok.htm",
    ),
    "F37": Fact(
        "Компилятор проверяет размер динамической памяти; `__NEW/__DELETE` не описаны",
        "DPA-302 v2.20, с. 185–186",
        _DPA302,
    ),
    "F38": Fact(
        "Тёплый сброс сохраняет RETAIN и PERSISTENT RETAIN, холодный — только PERSISTENT RETAIN, заводской — ничего",
        "DPA-302 v2.20, с. 193–194, табл. 8",
        _DPA302,
    ),
    "F39": Fact(
        "RETAIN переинициализируются при холодном и заводском сбросе и при загрузке приложения; "
        "`saveretain`/`restoreretain` в «Оболочке ПЛК»",
        "DPA-302 v2.20, с. 195–196",
        _DPA302,
    ),
    "F40": Fact(
        "RETAIN и PERSISTENT — общая область: SRAM до 1 МБ или файл до 100 МБ (`[PsRetain]`, `StorageSize` по "
        "умолчанию 1 КБ); запись синхронизируется при любом изменении",
        "DPA-302 v2.20, с. 194–195, 291",
        _DPA302,
    ),
    "F41": Fact(
        "PERSISTENT RETAIN объявляются в объекте «Persistent-переменные…» (`PersistentVars`)",
        "DPA-302 v2.20, с. 195; курс, 5.6",
        _DPA302,
    ),
    "F47": Fact(
        "PLCopenXML в CODESYS — подмножество; при экспорте VAR_GLOBAL и VAR_GLOBAL CONSTANT нельзя держать в "
        "одном списке",
        "CODESYS Online Help, Exporting and Importing Projects; Command: Export PLCopenXML",
        "https://content.helpme-codesys.com/en/CODESYS%20Development%20System/_cds_cmd_export_plcopenxml.html",
    ),
    "F50": Fact(
        "В учебных проектах вендора используются Standard (`R_TRIG`, `LEN`), Standard64 (`WLEN`) и Util",
        "курс, 4.14, 5.13, 17.16",
        _COURSE + "okno_programmnogo_bloka_s_kodom_na_yazyke_st.htm",
    ),
    "F51": Fact(
        "SysFile и SysDir описаны; работа с файлами синхронная и блокирует задачу",
        "курс, 14.2–14.5",
        _COURSE + "biblioteki_2.htm",
    ),
    "F52": Fact(
        "Время: SysTime, SysTimeRtc, PsTime (`PsTimeGetUtcTimeNs` — UTC в нс, `ULINT`)",
        "курс, 15.2; DPA-302 v2.20, с. 234, 390",
        _COURSE + "biblioteki_dlya_raboty_s_datoj_i_vremenem.htm",
    ),
    "F53": Fact(
        "CAA File в документации нет; плейсхолдер в описании устройства разрешается на CAA File 3.5.17.0",
        "пакет 1.7.2.6, REGUL R500 71-W.devdesc.xml",
        _PACKAGE,
    ),
    "F54": Fact(
        "Библиотеки вендора: PsJsonConvertions, PsLog, PsSysFile, PsTime, PsUnittest, PsUtils и др. (префикс Ps)",
        "DPA-302 v2.20, прил. Л, с. 315–398",
        _DPA302,
    ),
    "F58": Fact(
        "Данные каналов Modbus — массив WORD через «Соотнесение входов/выходов» (I/O mapping)",
        "DPA-302.1 v1.7, с. 16–18",
        _DPA302_1,
    ),
    "F60": Fact(
        "В режиме Modbus Slave области данных привязываются библиотекой PsModbusSerialSlave; описаны стратегии "
        "с M-памятью, ссылками и структурами",
        "DPA-302.1 v1.7, с. 19–24",
        _DPA302_1,
    ),
    "F73": Fact(
        "coUnit 1.2.0.0 ссылается на 16 библиотек, в том числе Breakpoint Logging Functions 3.5.5.0 "
        "(фиксированная версия), IECStringUtils, Base Interfaces",
        "по исходникам coUnit (forge.codesys.com/lib/counit); наличие в Astra.IDE — проверить вручную",
        "https://forge.codesys.com/lib/counit/",
    ),
    "F78": Fact(
        "В приложении есть «Менеджер библиотек», свои библиотеки и репозиторий библиотек",
        "курс, 4.4",
        _COURSE + "struktura_dereva_proekta.htm",
    ),
    "F79": Fact(
        "Вендор пишет полные имена с пространствами имён; имена функций вендора менялись между версиями",
        "DPA-302.6, с. 9–11; DPA-302 v2.20, с. 9, 390, 393",
        _DPA302_6,
    ),
    "F85": Fact(
        "В патче 1.7.2.5 добавлен запрет на ссылки и указатели в символьной конфигурации",
        "reglab.ru/soft, «Патч 1.7.2.5»",
        _SOFT,
    ),
}

RISKS: dict[str, str] = {
    "R1": "Устройство и дерево проекта не переносятся: новый проект мастером Regul, код — импортом, "
    "дерево устройств — вручную",
    "R8": "OPC UA: ФБ с REFERENCE/POINTER (возможно, и с интерфейсными переменными) ломают символьную "
    "конфигурацию — фасад GVL с плоскими типами",
    "R10": "PERSISTENT синхронизируются при каждой записи — копить приращение и переносить с периодом",
    "R11": "Объект PersistentVars не создаётся автоматически — вручную или импортом PLCopenXML",
    "R12": "RETAIN сбрасываются при загрузке и холодном сбросе — saveretain/restoreretain в методике",
    "R13": "Приоритеты задач REGUL 0–15, 0 и 1 зарезервированы — таблица соответствия задач",
    "R14": "pack_mode на ЦП II типа (ARM) — не упаковывать структуры регистров",
    "R15": "Наследование ФБ не подтверждено — композиция и интерфейсы, каждая правка с `// PORT:`",
    "R16": "Атрибуты strict, call_after_init не описаны — проверить компиляцией и поведением",
    "R17": "Перечисления с базовым типом, STRUCT EXTENDS не описаны — явные значения, композиция",
    "R18": "coUnit может не собраться — тесты логики в CODESYS 3.5.17.30, на REGUL — интеграционные",
    "R19": "CAA File не описана — SysFile в отдельной задаче с низким приоритетом",
    "R20": "Источник времени `Now() : LTIME` — реализация на `PsTimeGetUtcTimeNs`/`SysTimeRtc`",
    "R23": "Кириллица в строках — WSTRING или латиница в ПЛК",
}

CHECKLIST: dict[str, str] = {
    "A4": "Репозиторий библиотек: Standard, Standard64, Util, CAA File, SysFile, SysDir, SysTime, "
    "IECStringUtils, Base Interfaces, Breakpoint Logging Functions — версии",
    "B3": "Импорт PLCopenXML из CODESYS 3.5.17.30: методы, свойства, интерфейсы, EXTENDS/IMPLEMENTS, атрибуты, "
    "PersistentVars",
    "C1": "`FUNCTION_BLOCK FB_B EXTENDS FB_A` и вызов `SUPER^.Method()`",
    "C2": "`THIS^`, `ABSTRACT` (ФБ, метод, свойство), `FINAL`",
    "C3": "Спецификаторы `PRIVATE`, `PROTECTED`, `INTERNAL`; свойство в пользовательском ФБ",
    "C4": "Наследование интерфейсов, `__QUERYINTERFACE`, `__QUERYPOINTER`",
    "C5": "`{attribute 'strict'}`: неквалифицированное обращение даёт ошибку",
    "C6": "`call_after_init`, `hide`, `no_check`, условная компиляция `{IF defined(...)}`",
    "C7": "Перечисление с базовым типом",
    "C8": "`STRUCT ... EXTENDS`; `UNION` в составе структуры",
    "C9": "`pack_mode` на выбранном ЦП (тип I/II/III)",
    "C10": "CAA File: запись CSV на ВПЛК",
    "C11": "`LTIME`: литералы, арифметика, преобразования, таймеры на LTIME",
    "C12": "`__NEW`/`__DELETE` и настройки динамической памяти",
    "C13": "`VAR_IN_OUT` (в том числе `CONSTANT`) с массивами и строками",
    "C14": "`{attribute 'linkalways'}` у GVL тестов: GVL без ссылок из кода попадает в приложение (пункт "
    "добавлен в чек-лист миграции по итогам инвентаризации)",
    "D1": "Создать «Persistent-переменные…» и добавить пути экземпляров",
    "G4": "Ошибка символьной конфигурации на ФБ с REFERENCE/POINTER и интерфейсными переменными",
    "H2": "Установить coUnit 1.2.0.0 и собрать тестовый проект",
    "H3": "Прогон coUnit на ВПЛК: результаты и путь к xUnit-файлу",
    "J1": "Допустимые приоритеты задач на выбранном ЦП, сторожевой таймер, системные задачи",
}

SECTIONS: dict[str, str] = {
    "§2.9": "раздел 2.9 исследования (Modbus): `ModbusUserRequest2` с буфером `ADR`/`SIZEOF` (DPA-302.1 v1.7)",
    "§2.5": "раздел 2.5 исследования (типы данных)",
}


def ref_kind(ref: str) -> str:
    """Вид ссылки: fact, risk, checklist, section."""
    if ref.startswith("§"):
        return "section"
    if ref.startswith("F"):
        return "fact"
    if ref.startswith("R"):
        return "risk"
    return "checklist"
