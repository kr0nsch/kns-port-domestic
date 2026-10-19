# Changelog

Все заметные изменения проекта записываются в этот файл.

Формат — [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/), версии — по
[Semantic Versioning](https://semver.org/lang/ru/spec/v2.0.0.html).

## [Unreleased]

### Added

- Перенос на Astra.IDE, этап 2 — адаптированный код (`targets/astra/`, README там же): приложение КНС-1
  (`targets/astra/src`, флагман `main` = `505ce14`) и библиотека plc-process-lib (`targets/astra/lib/src`,
  тег `v1.0.0` = `bd9df2a`) без правок кода оригиналов: 283 маркера проверки
  `// PORT: [категория] проверить в Astra.IDE — что (пункт)` у конструкций, которые документация РегЛаб не
  подтверждает (наследование ФБ и интерфейсов, спецификаторы доступа, свойства, `strict`, перечисления с
  базовым типом, `LTIME`, `VAR_IN_OUT CONSTANT`, CAA File, `SysTimeRtcHighResGet`, Persistent Variables,
  смешанный GVL, OPC UA, запись PERSISTENT). Новые объекты сборки для ПЛК REGUL — слой Modbus RTU
  `PRG_ModbusMap_Regul`, `F_MbStatusOk_Regul`, `GVL_ConstRegul` (3 маркера правки `[comm]`, 68 строк):
  каналы `Modbus Serial Outer Slave` с массивами WORD ↔ регистры `GVL_IO`, признаки обмена по статусу
  канала (до проверки E2 — «потеря связи»).
- `upstream/`: снимки `src` оригиналов на коммитах переноса и `upstream/SOURCES.json` (коммиты, ревизии,
  даты, замена плейсхолдеров).
- `tools/port_checks.py`: маркеры проверки по правилам (17 правил, пункты B3, C1–C15, D1), отчёт по пунктам
  чек-листа, `--fix`, `--resolve` / `--fail` с решениями в `targets/astra/port_checks.json`. Тесты —
  `tools/port_tests/test_port_checks.py`.
- `tools/upstream_delta.py`: дельта новой версии флагмана или библиотеки для перенесённых файлов — замена,
  трёхстороннее слияние `git merge-file` с сохранением правок переноса, копирование, удаление; `--apply`
  записывает результат (конфликты — с маркерами git) и переводит снимок на новый коммит; `--verify`
  сверяет снимки с коммитами. Тесты — `tools/port_tests/test_upstream_delta.py` (временный репозиторий git).
- `docs/port_metrics.md` и `.json` — первый отчёт: 10 874 значимые строки оригинала без изменений,
  3 новых объекта (68 строк), маркеры по категориям и пунктам чек-листа.
- iec_checker 0.4 по адаптированному коду: `targets/astra/iec_checker_allow.toml` и
  `targets/astra/lib/iec_checker_allow.toml` — копии обоснований оригиналов и три записи для объектов
  сборки REGUL; необоснованных находок 0.
- `docs/USAGE.md`: как оценить и выполнить перенос своего проекта CODESYS в Astra.IDE с инструментами и
  чек-листом этого репозитория.
- Пункты чек-листа C15 (`SysTimeRtcHighResGet`) и C16 (компилируются ли POU вне задач); строка PMI-39 в
  бланке протокола (ПМИ флагмана версии 0.4).
- Ключ `checker` в обоснованиях iec_checker (`run_iec_checker.py --checker v0.4|nightly`) — из
  plc-repo-template.
- Перенос КНС-1 и `plc-process-lib` на Astra.IDE, этап 1 — инструменты и анализ (README, «Статус»):
  целевая среда — Astra.IDE (решение инженера), MasterSCADA 4D — позже (`docs/ASSUMPTIONS.md`, P1–P8).
- `docs/differences.md`: различия CODESYS 3.5.17 и Astra.IDE по 12 разделам («аспект | CODESYS | Astra.IDE |
  решение | источник») и приложение — 93 факта со ссылками на документы РегЛаб и справку CODESYS;
  выборочная перепроверка по первоисточникам 19.10.2026.
- `tools/inventory.py` (каталог возможностей `tools/inventory_catalog.py`, источники `tools/inventory.toml`):
  инвентаризация возможностей CODESYS в библиотеке и флагмане — ООП, прагмы, библиотеки, типы, конструкции,
  RETAIN/PERSISTENT, `AT`, задачи, ключевые слова других сред — с риском для Astra.IDE и ссылками на факты;
  читает коммиты (`git archive`), пропускает пример шаблона; `--check` — отчёт актуален.
  Отчёт `docs/inventory.md` и `docs/inventory.json` (библиотека — `integrate` `4b0541c`; числа сверены
  ручным подсчётом по исходникам). Тесты — `tools/inventory_tests/`.
- `tools/st_to_plcopen.py`: раскладка -> PLCopen XML (TC6 2.01, вариант CODESYS для CODESYS 3.5 и Astra.IDE)
  и обратно; подмножество — POU, DUT, GVL и Persistent Variables, тела на ST, методы, свойства, интерфейсы,
  папки; проверка по официальной схеме TC6 2.01 (`--xsd auto`). `tools/plcopen/verify_codesys.py` — эталонная
  проверка в CODESYS 3.5.17.30: импорт в приложение и пул POU, сравнение текстов, сборка, обратный экспорт.
  Проверено: фикстура всех конструкций и исходники `plc-process-lib` — 0 ошибок (`docs/plcopen.md`).
- `tools/port_metrics.py`: метрики переноса по файлам, объектам, источникам и итого — строки без изменений,
  изменённые, переписанные, удалённые и добавленные; маркеры `// PORT: [категория] причина` в 14 категориях;
  `--strict` — код 1 при правке без маркера. Отчёт `docs/port_metrics.md` (пока — методика и команда: кода в
  `targets/astra/src/` нет). Тесты — `tools/port_metrics_tests/`.
- `docs/migration_checklist.md` (подготовка, типы и библиотеки, ввод-вывод, связь, HMI, испытания по той же
  ПМИ, риски, пункты «проверить вручную» A1…K4), `docs/test_protocol_astra.md` (бланк протокола ПМИ флагмана
  в Astra.IDE), `docs/BUILD_ERRORS.md` — цикл исправлений: итерации, разбор сообщений `N.k`, сводка.
- CI: шаг «Код для Astra.IDE (targets/astra)» — `st_lint --strict` адаптированного кода и PLCopen XML в
  артефакте `build-reports` (пока каталога нет — пропуск); pytest запускает и тесты инструментов переноса.
- Раскладка исходников ST в `src/` и `tests/` и её формальный контракт `docs/LAYOUT.md`.
- Пример шаблона (в этом репозитории удалён, см. Removed): `E_DeviceMode`, `ST_ExampleCmd`, `ST_ExampleSts`, `GVL_Const`, интерфейс `I_Resettable`,
  функция `F_Clamp`, `FB_Example` (метод `Acknowledge`, реализация `Reset`, свойство `Count`), `PRG_Main`.
- Тесты CfUnit (coUnit 1.2.0.0) примера шаблона (удалены вместе с ним): наборы `FB_F_Clamp_Test` (7 тестов), `FB_Example_Test` (11 тестов:
  пороги и гистерезис, отказ и квитирование, режимы, ограничение параметров, счётчик, сброс через
  `I_Resettable`) и `PRG_Tests`.
- Инструменты: `tools/assemble.py`, `tools/check/` (линтер `st_lint.py`, запуск iec_checker и RuSTy),
  скрипты CODESYS Scripting в `tools/codesys/`.
- `tools/codesys/cds.py` — импорт, сборка, тесты coUnit в CODESYS Control Win V3 (пользовательский
  процесс), экспорт, roundtrip, JUnit и отчёт из консоли; настройки — `tools/codesys/config.json`.
  Проверено в CODESYS 3.5.17.30.
- `cds.py library [--install] [--compiled] [--released]`: библиотека CODESYS из `src/` — `build/<имя>.library`
  (и `.compiled-library`) с Project Information из `config.json: library`, «проверить все объекты пула»
  с ошибками в строках `src/`, установка в репозиторий библиотек; `library --uninstall [--all-versions]`.
  Проверено в CODESYS 3.5.17.30.
- Библиотеки-зависимости портфолио: в `config.json: libraries` — закрепление версии (точная или `*`),
  пространство имён ссылки, плейсхолдер, `install_from` и `build_from_repo`; `cds.py deps [--rebuild]
  [--check]`; `import`/`build`/`test` сами собирают недостающую библиотеку в соседнем репозитории
  (`cds.py library --install` там) и повторяют задание (`--no-deps` — отключить). Найденная библиотека
  проверяется и по её собственным зависимостям (рекурсивно); цикл зависимостей между репозиториями —
  отказ, а не бесконечная цепочка сборок. Ссылки `library.libraries` подключаются и к проектам
  приложения и тестов репозитория-библиотеки. Учёт установок: из какой рабочей копии и коммита
  поставлена версия.
- Разделы `library` и `library_repository` в `tools/codesys/config.json`, глобальная блокировка
  репозитория библиотек; тесты `tools/tests/test_cds_library.py`.
- CI GitHub Actions: ruff, mypy, pytest, сборка ST, линтер (`--strict`), iec_checker v0.4 (закреплён
  по размеру и SHA-256); необязательно — iec_checker `nightly` (образ закреплён по дайджесту) и RuSTy.
- Документы: архитектура, ручные шаги, допущения, отчёты статанализа и тестов, шаблоны ТЗ
  (ГОСТ 34.602-2020) и ПМИ.
- `LICENSE` (MIT), `.gitignore`, `.gitattributes`, `.editorconfig`.
- `cds.py check [--tests]`: компиляция всех объектов `src/` (и `tests/`) — и тех, что не достижимы из
  задач и которые `build` не компилирует (программа без задачи, ФБ без экземпляра, неиспользуемый
  DUT): «Проверить все объекты пула» в проекте без устройства, проект на диск не пишется; ошибки — с
  файлом и строкой, код 1. Библиотеки — те же, что у `build`: ссылки из `config.json` и копии ссылок,
  которые добавляет само устройство (`#IoStandard`, `#CAA Device Diagnosis`, ...). Persistent
  Variables проверяются как GVL. Рекомендуемая полная проверка — `build`, `check --tests`, `test`,
  `roundtrip` (`docs/MANUAL_STEPS.md`, раздел 5). Проверено в CODESYS 3.5.17.30.
- Библиотека Standard по умолчанию: в `config.json` ключ `standard` (плейсхолдер `#Standard`, версию
  задаёт профиль, явные `namespace: Standard` и `qualified_only: false` — доступ и `TON`, и
  `Standard.TON`, как в проекте IDE) в `library.libraries`, то есть во всех режимах, в `check` и в
  библиотеке репозитория. Проверено в CODESYS 3.5.17.30 (TON, R_TRIG, CTU, CONCAT в режимах normal,
  test и library).
- `tools/tests/test_cds_config.py`: `config.json` репозитория проверяется на уровне схемы (разделы и
  ключи — как у эталона `tools/tests/fixtures/config_template.json`, описания режимов, задач и
  библиотек полные и разрешаются).
- Понижение `iec-checker` (`tools/st_flavors.py`) для конструкций CODESYS, которых нет в грамматике
  iec_checker 0.4 (раньше — ParserError): операторы `TIME()`/`LTIME()` (вызов заглушки `CDS__TIME()`,
  `CDS__LTIME()`; литерал длительности давал бы ложные ZeroDivision и PLCOPEN-CP28), константы в границах массивов и длинах строк (`ARRAY[0..GVL_Const.N - 1]`
  → числа по константам GVL, `VAR CONSTANT` и перечислений), поле и вызов элемента массива (`a[i].x` →
  `a.x[i]`, `afb[i](...)` → `afb(..., i)`), несколько индексов, длительности с пропуском единиц
  (`T#1h500ms` → `T#1H0M0S500MS`), пустой оператор `;`, пустые ветви и тела (`CDS__NOP();`), пустые
  `PROGRAM`/`FUNCTION` (`{}`), имена — ключевые слова iec_checker (`Priority` → `Priority_`),
  `WORD#16#FF`, `BOOL#1`, `1E3`, `AND_THEN`/`OR_ELSE`, управляющие слова в нижнем регистре, вложенные
  массивы; целые константные начальные значения подставляются числом. Пример
  `tools/tests/fixtures/lowering/` и эталон `tools/tests/golden/iec-checker-lowering/`; проверено
  бинарником v0.4 и на копиях plc-process-lib и s7-to-codesys (ошибок разбора 0). В псевдониме типа с
  десятичными границами (`TYPE T_Pct : INT(0..100) := 50;`) поддиапазон больше не убирается: iec_checker
  его разбирает и проверяет начальное значение (OutOfBounds).
- `tools/README.md`, «Понижение для iec_checker»: у каждой замены — влияние на находки, в том числе какие
  виды находок она может скрыть (PLCOPEN-N3 у переименованных имён, OutOfBounds у невычисленных границ и
  массивов в `STRUCT`, PLCOPEN-CP13 у рекурсии методов) или добавить; сводная таблица по проверкам
  iec_checker 0.4.
- Пример `tools/tests/fixtures/sourcemap/` с многострочными конструкциями и тесты карты строк после
  понижения: по меткам строк (`test_source_map_multiline_constructs`, все варианты сборки) и по находкам
  настоящего iec_checker (`test_integration_findings_point_to_source_lines`).
- Вариант `rusty`: `VAR_IN_OUT CONSTANT` → `VAR_IN_OUT` (R13); прокладка
  `tools/check/rusty_shims/codesys_conversions.st` — преобразования TIME/LTIME ↔ целые, битовые и REAL
  (`TIME_TO_DINT`, `UDINT_TO_TIME`, ...), которых нет в stdlib RuSTy 1.0.6.
- `st_lint` STL007: составные префиксы массивов `a` + префикс элемента (`astAlarm`, `afbAlarm`,
  `aitfDev`, `altStart`, `audiReserve`), настройка `array_element_prefixes` (`match`, `any`, `off`);
  проверка ключей `st_lint.toml` (неизвестный ключ или значение не того вида — ошибка настроек).

### Changed

- `tools/port_metrics.py`: маркеры проверки (`проверить в Astra.IDE`) правку не помечают и лишними не
  считаются; пары деревьев по меткам (`--orig МЕТКА=…`, `--adapted МЕТКА=…`); раздел «Правки по категориям»
  (маркеры, объекты, файлы, строки) и «Маркеры проверки по пунктам чек-листа»; `--check` — отчёт устарел;
  по умолчанию — снимки `upstream/` и `targets/astra/` с исключением `plc-process-lib:PRG_Main`.
- CI, шаг «Код для Astra.IDE»: `port_checks --strict`, `port_metrics --check --strict`, PLCopen XML
  приложения и библиотеки, iec_checker по обоим деревьям; `st_lint` проверяет и `targets/astra/` (пути в
  `tools/check/st_lint.toml`, исключения STL003 для `GVL_Persist`, STL008 для `GVL_ConstRegul`).
- `tools/inventory.toml`: ревизии закреплены на коммитах переноса; `docs/inventory.md` пересобран
  (объекты `src` и `tests`: флагман — 121, библиотека — 116).
- `docs/differences.md`, `migration_checklist.md`, `BUILD_ERRORS.md` (заготовка итерации 1),
  `ARCHITECTURE.md`, `ASSUMPTIONS.md` (P9–P16), `STATIC_ANALYSIS.md`, README по стандарту портфолио.
- mypy проверяет инструменты как для win32 (`platform = "win32"`), файлы `.st` в языковой панели GitHub —
  Pascal (`linguist-language`), сводка iec_checker в CI без раздела обоснованных находок (предел сводки
  GitHub) — из plc-repo-template.
- README, `docs/ARCHITECTURE.md`, `docs/TEST_REPORT.md`, `docs/STATIC_ANALYSIS.md` описывают этот
  репозиторий, а не пример шаблона; `docs/ASSUMPTIONS.md` — решения переноса (P1–P8), решения о примере
  шаблона убраны вместе с ним.
- `tools/check/st_lint.toml`: у тестов адаптированного кода (`targets/*/tests/*`), как у `tests/`,
  «магические числа» (STL008) не проверяются. `tools/check/iec_checker_allow.toml` пуст: обоснования
  относились к удалённому примеру.
- `docs/differences.md`, F47: формулировка о формате `*.export` уточнена по справке CODESYS.
- Тесты `tools/tests/test_cds.py` и `test_cds_library.py` берут настройки из эталона
  `tools/tests/fixtures/config_template.json`, а не из `config.json` репозитория: проект может менять
  свои библиотеки, задачи и библиотеку репозитория без исключения тестов шаблона (`--deselect`).
  Проекту, который исключал их раньше, после обновления `tools/` исключения `test_cds.py` и
  `test_cds_library.py` в `pyproject.toml` и свои тесты-замены для них нужно убрать: тесты-замены,
  подменявшие `config.json` в модулях тестов шаблона, с новыми тестами не работают (проверено на копии
  s7-to-codesys: 7 падений замены, а сами тесты шаблона и `test_cds_config.py` проходят с его
  `config.json`).
- `tools/check/st_lint.toml` принадлежит проекту: тест `test_toml_matches_defaults` заменён на
  `test_template_toml_matches_defaults` (с умолчаниями сравнивается эталон
  `tools/tests/fixtures/st_lint_template.toml`) и `test_repository_toml_is_valid` (файл репозитория
  разбирается, все ключи известны); тесты линтера берут настройки из эталона. Проекту, который исключал
  `test_toml_matches_defaults` (`--deselect`), исключение нужно убрать.
- `test_run_rusty.py::test_integration_sample_passes` проверяет фикстуру со своим пустым файлом
  исключений, а не с `tools/check/rusty_exclude.txt` репозитория.
- `cds.py import`, `library`, `check`: два описания `libraries`, которые нашли одну библиотеку, дают
  одну ссылку (одинаковые сливаются с предупреждением, разные — отказ до открытия проекта, код 1);
  ссылки Library Manager после импорта — в поле `references` отчёта `build/import.json`.

### Removed

- Пример шаблона в `src/` и `tests/` (`E_DeviceMode`, `ST_ExampleCmd`, `ST_ExampleSts`, `GVL_Const`,
  `I_Resettable`, `F_Clamp`, `FB_Example`, `PRG_Main`, наборы `FB_F_Clamp_Test`, `FB_Example_Test`,
  `PRG_Tests`): код этого репозитория — `targets/astra/src/` (этап 2). `assemble`, `st_lint`, iec_checker и
  RuSTy с пустыми `src/` и `tests/` проходят.

### Fixed

- `st_lint` STL007: `VAR_IN_OUT CONSTANT` (и `VAR_INPUT CONSTANT`) больше не считается секцией
  констант — для параметров только для чтения действуют префиксы по типу, а не UPPER_SNAKE_CASE.
- Понижение `iec-checker`: начальное значение `[...]` массива в поле структуры убирается вместе с
  типом массива (раньше `x : REAL := [...]` — ParserError); `ARRAY[0..2 * N]` — умножение в границе
  больше не принимается за `ARRAY[*]`.
- Тесты coUnit: функции `TEST` и `TEST_FINISHED` вызываются с пространством имён (`coUnit.TEST(...)`) —
  без него сборка в CODESYS 3.5.17.30 давала ошибки C0046/C0035.
- `cds.py build`/`test`: перед открытием проекта удаляется кэш предкомпиляции CODESYS — с ним
  сломанное объявление ФБ с методами собиралось с «0 ошибок», а исправленное давало старую ошибку.
- `cds.py`: устаревший файл блокировки `<проект>.~u` (CODESYS остановлен по таймауту или упал)
  удаляется, проект, открытый в IDE, — понятный отказ с кодом 3 вместо трассировки.
- `cds.py import`: переименование только регистром (файл, метод, свойство, папка) доходит до проекта.
- `cds.py test`: старые `build/junit.xml` и `build/test-results.json` удаляются перед прогоном;
  неудачный вход в рантайм — одна строка с причиной и код 3 вместо трассировки; имя пользователя
  рантайма не пишется в журнал.
- `docs/MANUAL_STEPS.md`, `README.md`: команды без `& rem` — работают в cmd, PowerShell и Git Bash.
- `cds.py import`: ссылка на библиотеку другой версии заменяется (раньше оставалась старая, и в проекте
  оказывались обе); новейшая версия выбирается по номеру, а не по строке (`1.10` новее `1.9`); все
  недостающие библиотеки — в одном сообщении, до изменения проекта.
- `cds.py`: переменные рабочей копии (`CDS_REPO_ROOT`, `CDS_CONFIG`, `CDS_PROJECT*`, `CDS_LIBRARY*`) не
  читаются из `HKCU\Environment` — заданные через `setx`, они действовали бы на все git worktree сразу.
- Кэш предкомпиляции: имя по расширению файла (`<имя>_library.precompilecache` у библиотеки) — сборка
  библиотеки больше не удаляет кэш проекта `<имя>_project.precompilecache`.
