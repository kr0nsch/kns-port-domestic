# Отчёт о тестировании

Что и чем проверено в этом репозитории. Запись «проверено в CODESYS» появляется только после реального
прогона, «собирается в Astra.IDE» — только после записи инженера в [BUILD_ERRORS.md](BUILD_ERRORS.md).

<!-- cds:test-report:begin (раздел обновляет `python tools/codesys/cds.py report`) -->
## Последний прогон в CODESYS

Тестов ST (coUnit) в `tests/` этого репозитория нет: пример шаблона удалён, тесты библиотеки и флагмана
живут в их репозиториях. Раздел заполнит `cds.py report`, если тесты появятся (этап 2,
`targets/astra/tests`).
<!-- cds:test-report:end -->

## Инструменты на Python

2026-10-19, Windows, Python 3.12, локально; в CI — те же команды на Ubuntu.

| Проверка | Итог |
|---|---|
| `python -m pytest` | 747 пройдено, 2 пропущено (интеграционные тесты iec_checker: в `src/` нет POU) |
| `python -m ruff check .`, `python -m ruff format --check .` | без замечаний |
| `python -m mypy` (strict) | без ошибок |

Тесты инструментов переноса: `tools/inventory_tests/` (инвентаризация, в том числе на временных
репозиториях git), `tools/port_metrics_tests/` (метрики и маркеры `// PORT:`, в том числе тесты свойств
на hypothesis), `tools/plcopen/tests/` (эталоны XML, цикл XML → раскладка, схема TC6 2.01, разбор
настоящего экспорта CODESYS, `verify_codesys.py` без CODESYS).

## PLCopen XML: импорт и сборка в CODESYS 3.5.17.30

2026-10-19, CODESYS V3.5 SP17 Patch 3 (3.5.17.30), Standard 3.5.17.0,
`python tools/plcopen/verify_codesys.py --structural` с тремя раскладками: 24 прогона за 115 с.

| Раскладка | Элементов дерева | С текстами объявлений (`tc6_0201`, `tc6_0200`; приложение и пул POU) | Только TC6 (`--no-plaintext`) |
|---|---|---|---|
| фикстура `tools/plcopen/tests/fixtures/constructs` | 61 | без потерь, тексты совпадают, 0 ошибок и 0 предупреждений, экспорт CODESYS → та же раскладка | 11 ошибок компиляции: `VAR_INST` и `PRIVATE FINAL` (ожидаемые потери, [plcopen.md](plcopen.md#только-tc6---no-plaintext)) |
| `plc-process-lib`, `main` `20d9528`, `src/` | 184 | то же | 0 ошибок |
| `plc-process-lib`, `integrate` `4b0541c`, `src/` | 244 | то же | 0 ошибок |

Тексты объявлений и тел, которые CODESYS показал после импорта, дополнительно сверены с файлами
раскладки отдельным скриптом без `stlayout`: 158 текстов (`main`) и 242 текста (`integrate`), расхождений
нет. Файлы XML проходят официальную схему TC6 2.01 (`--xsd auto`); одинаковые исходники дают побайтно
одинаковый файл. Подробности и ограничения — [plcopen.md](plcopen.md#эталонная-проверка-в-codesys-351730).

## Сборка в Astra.IDE

Не выполнялась: это шаг инженера ([BUILD_ERRORS.md](BUILD_ERRORS.md), итерация 1 — фикстура конструкций и
библиотека как есть).
