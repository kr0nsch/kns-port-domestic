# PLCopen XML из раскладки: `tools/st_to_plcopen.py`

Конвертер переводит исходники в раскладке [LAYOUT.md](LAYOUT.md) в файл PLCopen XML (TC6, версия 2.01) в том
варианте, который читают CODESYS 3.5 и среды на его основе. Главная цель — Astra.IDE (РегЛаб, ПЛК REGUL):
по исследованию она построена на CODESYS V3.5 SP17 и экспортирует PLCopenXML с теми же расширениями 3S
(`_research/port/astra_ide.md`, F43–F47). Эталонная проверка — импорт в CODESYS 3.5.17.30 скриптом:
файл импортируется, собирается, тексты сверяются с исходниками, экспорт CODESYS читается обратно.

## Быстрый старт

```bash
# XML из src/ репозитория -> build/plcopen/<имя каталога>.xml
python tools/st_to_plcopen.py
# адаптированный код для Astra.IDE (раскладка в targets/astra/src)
python tools/st_to_plcopen.py --src targets/astra/src --out build/plcopen/astra.xml
# любая раскладка, например исходники библиотеки, с проверкой по официальной схеме TC6 2.01
python tools/st_to_plcopen.py --root ../plc-process-lib --xsd auto
# как пишет экспорт CODESYS и Astra.IDE (пространство имён tc6_0200)
python tools/st_to_plcopen.py --namespace tc6_0200
# обратно: PLCopen XML с текстами объявлений (наш файл или экспорт CODESYS/Astra.IDE) -> раскладка
python tools/st_to_plcopen.py --reverse export.xml --to build/from-xml
# эталонная проверка в CODESYS 3.5.17.30 (Windows): фикстура всех конструкций и исходники библиотеки
python tools/plcopen/verify_codesys.py
python tools/plcopen/verify_codesys.py --case astra=targets/astra --structural
```

Ключи `st_to_plcopen.py`: `--tests` (добавить `tests/` в папку `Tests`), `--exclude ИМЯ`, `--name`,
`--timestamp` (по умолчанию — `SOURCE_DATE_EPOCH` или текущее время UTC), `--no-folders` (без папок
проекта), `--no-plaintext` (только структурная часть TC6, см. ниже), `-q`. Коды выхода: 0 — успех;
1 — ошибки раскладки, преобразования или XSD (файл при ошибках преобразования не пишется);
2 — неверные аргументы.

## Формат файла

- Корень — `<project xmlns="http://www.plcopen.org/xml/tc6_0201">` (по умолчанию) или `tc6_0200`.
  Экспорт CODESYS 3.5 и Astra.IDE пишет `tc6_0200`. Импорт CODESYS 3.5.17.30 принимает оба варианта
  (проверено, таблица ниже); если Astra.IDE откажется от `tc6_0201`, файл пересобирается с
  `--namespace tc6_0200`, содержимое то же.
- Форма — «экспорт выбранных объектов» CODESYS: `types/dataTypes`, `types/pous`, пустой
  `instances/configurations`, остальное — в `addData` проекта с расширениями
  `http://www.3s-software.com/plcopenxml/...`. Имена расширений и их вложенность сняты с экспорта
  CODESYS 3.5.17.30 той же фикстуры (`proj.export_xml`, с текстами объявлений и без них).
- Каждый объект несёт и структурное описание TC6, и исходный текст объявления
  (`interfaceasplaintext`, как экспорт с флагом «объявления как обычный текст»). Импорт CODESYS берёт
  текст, поэтому объявления переносятся без потерь: комментарии, прагмы, порядок секций, модификаторы.
  Тела — текст ST как есть (`body/ST/xhtml`).
- ObjectId — UUID5 от вида, папки и имени объекта: одинаковые исходники дают побайтно одинаковый файл.

## Поддерживаемое подмножество

Все строки таблицы есть в фикстуре `tools/plcopen/tests/fixtures/constructs/` и проверены импортом и
сборкой в CODESYS 3.5.17.30 (раздел «Эталонная проверка»).

| Конструкция раскладки | Где в XML | Структурная часть TC6 |
|---|---|---|
| `TYPE ... STRUCT` (начальные значения, массивы, строки с длиной, комментарии) | `dataType/baseType/struct` | полная |
| `STRUCT EXTENDS` | то же + `addData` `datatypeinheritance` | наследование — расширение CODESYS |
| перечисление: без значений, со значениями, с базовым типом (`) INT;`), атрибуты `qualified_only`, `strict` | `dataType/baseType/enum` (+ `baseType`), `attributes` | полная |
| псевдоним типа (`STRING(20)`), поддиапазон (`INT(0..100)`) | `dataType/baseType` (`string`, `subrangeSigned`/`subrangeUnsigned`) | полная |
| `UNION` | `addData` `union` | расширение CODESYS (в TC6 объединений нет) |
| `FUNCTION` (с типом результата и без), `FUNCTION_BLOCK`, `PROGRAM` | `pou` (`function`, `functionBlock`, `program`) | полная |
| секции `VAR_INPUT`, `VAR_OUTPUT`, `VAR_IN_OUT`, `VAR`, `VAR_TEMP`, `VAR_EXTERNAL` | `inputVars` … `externalVars` | полная |
| `CONSTANT`, `RETAIN` у секций, `VAR_IN_OUT CONSTANT` | атрибуты `constant`, `retain` | `VAR_IN_OUT CONSTANT` — нестандартное сочетание |
| `VAR_STAT` | `globalVars` внутри интерфейса POU (как у CODESYS) | приближённая |
| тела на ST: все операторы, вложенные комментарии, типизированные литералы, `S=`/`R=`, `REF=`, `AND_THEN` | `body/ST` | полная (текст) |
| `AT %IX0.0` | `variable/@address` | полная |
| `{attribute ...}` у объектов и переменных | `addData` `attributes` | расширение CODESYS |
| `ARRAY[*]`, `REFERENCE TO`, `POINTER TO` | `derived name="ARRAY[*] OF REAL"`, `derived name="REFERENCE TO REAL"`, `pointer` | `ARRAY[*]` и `REFERENCE TO` — текстом в `derived` (так же пишет CODESYS) |
| GVL: `VAR_GLOBAL`, `CONSTANT`, `RETAIN`, несколько блоков в одном списке | `addData` `globalvars` (+ `mixedattrsvarlist`) | расширение CODESYS |
| Persistent Variables (`*.pvl.st`) | тот же `globalVars` с `persistent="true"` | создаётся объект PersistentVars |
| методы ФБ и программ: `PUBLIC`/`PRIVATE`/`PROTECTED`/`INTERNAL`, `ABSTRACT`, `FINAL`, `FB_init`, `VAR_INST`, `SUPER^`, `THIS^` | `pou/addData` `method` (+ `accessmodifiers`) | расширение CODESYS; см. «Только TC6» |
| свойства: Get, Set, оба, локальные переменные аксессора | `pou/addData` `property` | расширение CODESYS |
| `FUNCTION_BLOCK ABSTRACT`/`FINAL`, `EXTENDS`, `IMPLEMENTS` (несколько) | `pouinheritance`, `accessmodifiers` | расширение CODESYS |
| интерфейсы: `EXTENDS`, методы, свойства (Get, Set, оба) | `addData` `interface` | расширение CODESYS |
| папки проекта, в том числе вложенные | `addData` `projectstructure` | расширение CODESYS |

## Чего нет (ограничения)

- **Нет в раскладке — нет и в XML:** действия (`ACTION`) и переходы, графические языки (FBD, LD, SFC,
  CFC), визуализации, конфигурация задач (`instances/configurations` пустой), дерево устройств и
  конфигураторы обмена, Library Manager и ссылки на библиотеки, текстовые списки, свойства объектов
  («исключить из сборки» и т. п.), Project Information. В целевом проекте библиотеки (Standard и
  остальные) подключаются до импорта, задачи и устройства — вручную ([migration_checklist.md](migration_checklist.md)).
- **Persistent Variables — только в приложение.** В пул POU (проект без приложения, проект-библиотека)
  CODESYS такой объект не вставляет: «Невозможно вставить 'PersistentVars' под '<root>'». В приложении
  список Persistent Variables один: второй `*.pvl.st` — предупреждение конвертера и отказ импорта.
- **Обратное направление** требует текстов объявлений: файл `--no-plaintext` и экспорт CODESYS без флага
  «объявления как обычный текст» обратно не переводятся (ошибка «нет текста объявления»). POU и методы
  с телом не на ST (FBD, LD, SFC, CFC) пропускаются с предупреждением.
- **Символы, недопустимые в XML 1.0** (управляющие, кроме табуляции и перевода строки), — ошибка с путём
  исходника: их нужно убрать из файла.
- **Импорт в Astra.IDE** этим инструментом не проверен (среды на стенде нет): это шаг инженера
  ([BUILD_ERRORS.md](BUILD_ERRORS.md)), пункты B2–B3 чек-листа исследования.

### Только TC6 (`--no-plaintext`)

Для сред, которые читают только стандартную часть. CODESYS строит объявления из структуры сам (табуляции,
комментарии `///` из `documentation`), поэтому текст отличается от исходника. Чего структура не передаёт:

| Конструкция | Что происходит | Проверено в CODESYS |
|---|---|---|
| `VAR_INST` в методе | секции в TC6 нет — переменные теряются, конвертер предупреждает | тело метода не компилируется (C0046) |
| `ABSTRACT` у ФБ и метода | элемента нет — ФБ и метод становятся обычными, конвертер предупреждает | компилируется, но семантика другая |
| метод с модификатором доступа и `FINAL` | CODESYS восстанавливает `METHOD FINAL PRIVATE` — сам такой порядок не разбирает | C0026, C0006 (тот же файл даёт и экспорт CODESYS) |
| `PUBLIC` у методов и свойств | атрибута в `AccessModifiers` нет — остаётся доступ по умолчанию (тот же `PUBLIC`) | без последствий |
| комментарии и прагмы, кроме `{attribute}` | переносятся только комментарии к объявлениям (`documentation`) | — |
| начальные значения | текст значения без лишних пробелов (`T#5S`, `E_Mode.Auto`, `[3(1.0)]`) | компилируется |

Библиотека `plc-process-lib` в этом режиме импортируется и собирается без ошибок; в фикстуре ошибки дают
ровно две конструкции из таблицы (`VAR_INST`, `PRIVATE FINAL`). По умолчанию тексты объявлений пишутся,
и этих потерь нет.

## Эталонная проверка в CODESYS 3.5.17.30

`tools/plcopen/verify_codesys.py` (Python 3) пишет XML и запускает CODESYS без интерфейса со скриптом
`tools/plcopen/cds_import_check.py` (IronPython 2.7). Для каждого файла — два прогона в новых проектах:

- **app** — пустой проект с устройством CODESYS Control Win V3 (`DeviceID(4096, '0000 0001', '3.5.17.30')`),
  Standard через плейсхолдер, импорт в приложение (`app.import_xml`), задача MainTask → `PRG_Main`,
  полная сборка `app.rebuild()`; затем экспорт приложения (`export_xml`, с текстами объявлений)
  читается `st_to_plcopen.read_xml` и сравнивается с исходной раскладкой побайтно по файлам;
- **pool** — проект без устройства, импорт в пул POU (`proj.import_xml`), «Проверить все объекты пула»:
  компилируется всё, даже то, что не вызывает ни одна задача. PVL здесь заменяется GVL с тем же текстом
  без `PERSISTENT` (в пул PVL не вставляется), так же делает `cds.py check`.

Сверяются: сообщения импорта (`ImportReporter`), каждое ожидаемое по раскладке дерево (папки, объекты,
методы, свойства, аксессоры) и тексты объявлений и тел, сообщения компилятора. Итог — `build/plcopen/verify.md`
и `verify.json`. Прогон 19.10.2026, CODESYS V3.5 SP17 Patch 3 (3.5.17.30), Standard 3.5.17.0:

| Раскладка | Вариант XML | Режим | Объектов (ожид. / в CODESYS) | Расхождений | Ошибок импорта | Ошибок / предупр. компиляции | Экспорт CODESYS → раскладка | Итог |
|---|---|---|---|---|---|---|---|---|
| фикстура `constructs` | tc6_0201 | app | 61 / 61 | 0 | 0 | 0 / 0 | совпадает | OK |
| фикстура `constructs` | tc6_0201 | pool | 61 / 61 | 0 | 0 | 0 / 0 | — | OK |
| фикстура `constructs` | tc6_0200 | app | 61 / 61 | 0 | 0 | 0 / 0 | совпадает | OK |
| фикстура `constructs` | tc6_0200 | pool | 61 / 61 | 0 | 0 | 0 / 0 | — | OK |
| фикстура `constructs` | только TC6 (оба ns) | app, pool | 61 / 61 | — | 0 | 11 / 0 | — | потери TC6 (таблица выше) |
| `plc-process-lib`, main `20d9528` | tc6_0201, tc6_0200 | app, pool | 184 / 184 | 0 | 0 | 0 / 0 | совпадает | OK |
| `plc-process-lib`, main `20d9528` | только TC6 (оба ns) | app, pool | 184 / 184 | — | 0 | 0 / 0 | — | OK |
| `plc-process-lib`, integrate `4b0541c` | tc6_0201, tc6_0200 | app, pool | 244 / 244 | 0 | 0 | 0 / 0 | совпадает | OK |
| `plc-process-lib`, integrate `4b0541c` | только TC6 (оба ns) | app, pool | 244 / 244 | — | 0 | 0 / 0 | — | OK |

Библиотека (main): 50 DUT, 13 POU, 41 метод, 30 свойств с 30 аксессорами, 2 GVL, 7 интерфейсов, 11 папок.
Ветка integrate (выпуск 1.0 в работе) — рабочая копия на коммите `4b0541c` без незафиксированных
правок (первый прогон шёл на `44e8201`; `src/` с тех пор не менялся). Прогон повторён 19.10.2026 на
заново созданных файлах в отдельном каталоге (`--out`), вместе с вариантом «только TC6» (`--structural`):
итоги те же. Тексты объявлений и тел из CODESYS дополнительно сверены с файлами раскладки отдельным
скриптом без `stlayout` (построчно, без учёта концевых пробелов) — расхождений нет. Флагман
`kns-pump-station` не проверялся: его код ещё пишется и зависит от установленной библиотеки `PL`.

## Проверка по XSD

Официальная схема — plcopen.org, раздел [XML Exchange](https://www.plcopen.org/standards/xml-echange/) →
Downloads, «PLCopen XML version 2.01 xsd file» (zip с `tc6_xml_v201.xsd` от 28.04.2009). Условия
распространения в файле не указаны, поэтому схема в репозиторий не кладётся: `--xsd auto` и тесты
скачивают архив в `build/xsd/` и сверяют SHA-256 файла схемы
(`591b92ba65018a77c32ab9e606abf27bd810cb1f7761d972a85689531c51e20f`); локальную копию можно указать
переменной `PLCOPEN_XSD`. Файл `tc6_0200` проверяется после замены пространства имён на `tc6_0201`.
Проходят схему: наш файл во всех вариантах (`tc6_0201`, `tc6_0200`, только TC6, без папок), XML
исходников библиотеки и экспорт CODESYS фикстуры. Расширения CODESYS лежат в `addData`, схема их не
проверяет (`xsd:any`).

## Импорт в Astra.IDE (шаги инженера)

Названия пунктов меню — как в CODESYS 3.5; в Astra.IDE их сверить (чек-лист B2).

1. Проект REGUL создан мастером, в Library Manager приложения есть Standard (и библиотеки, которые
   нужны коду). Задачи и устройства — по [migration_checklist.md](migration_checklist.md).
2. `python tools/st_to_plcopen.py --src targets/astra/src --out build/plcopen/astra.xml --xsd auto`.
3. В дереве выделить Application → «Проект → Импорт PLCopenXML…» → файл → отметить все объекты.
   Папки проекта создаются из файла.
4. «Сборка → Генерировать код», сообщения импорта и компиляции — в [BUILD_ERRORS.md](BUILD_ERRORS.md).
5. Если импорт не принимает файл целиком, пересобрать с `--namespace tc6_0200`; если не принимает
   объекты ООП — записать сообщения (это ответ на пункт B3 чек-листа исследования).

## Тесты

`python -m pytest tools/plcopen/tests` (входят в общий `python -m pytest`):

- эталоны `golden/constructs.xml` и `golden/constructs-tc6only.xml` (обновление — `UPDATE_GOLDEN=1`);
- содержимое по конструкциям: типы, значения, секции, расширения ООП, папки, экранирование;
- цикл раскладка → XML → раскладка в обоих пространствах имён, запись файлов побайтно;
- настоящий экспорт CODESYS 3.5.17.30 (`fixtures/codesys_export/constructs-app.xml`) → раскладка;
- схема TC6 2.01 (маркер `network`: без сети и без lxml — пропуск);
- `verify_codesys.py` без CODESYS: ожидаемое дерево, сравнение, отчёт, задание; совместимость
  `cds_import_check.py` с IronPython 2.7.
