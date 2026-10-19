# Статический анализ

Находки `iec_checker` по `build/assembled/` (и `st_lint` по раскладке), которые не исправлены в коде, —
с обоснованием. Исправленные находки сюда не пишутся. Здесь же — итог проверки компиляции RuSTy.

Код в репозитории — только адаптированный для Astra.IDE (`targets/astra/`): в `src/` и `tests/` кода
нет, пример шаблона удалён вместе с его обоснованиями.

## Как запускается

| Инструмент | Где | Вход | Отчёт |
|---|---|---|---|
| `tools/check/st_lint.py --strict` | локально и в CI | `src/`, `tests/`, `targets/astra/src/`, `targets/astra/lib/src/` (пути — `tools/check/st_lint.toml`) | вывод в консоль, код выхода ≠ 0 при нарушениях |
| `tools/check/run_iec_checker.py --root targets/astra --allow targets/astra/iec_checker_allow.toml` | локально и в CI (шаг «Код для Astra.IDE»): iec_checker v0.4 | приложение КНС-1 | `build/iec_checker.json`, `.md` (в CI — `build/iec_checker_astra_app.*`) |
| `tools/check/run_iec_checker.py --root targets/astra/lib --allow targets/astra/lib/iec_checker_allow.toml` | то же | библиотека plc-process-lib | то же (в CI — `build/iec_checker_astra_lib.*`) |
| `tools/check/run_iec_checker.py --tests` | локально и в CI (обязательно); `--docker` — образ `nightly`, необязательное задание | `src/`, `tests/` (пусты) | `build/iec_checker.json`, `build/iec_checker.md` |
| `tools/check/run_rusty.py` | локально и в CI (необязательное задание) | `src/`, `tests/` (пусты) | `build/rusty.log`, `build/rusty.json` |

Обоснования подбираются под находки iec_checker v0.4 — той же версии, что в обязательном шаге CI.
Запись с ключом `checker` (`v0.4` или `nightly`) применяется и проверяется на использование только при
прогоне своей версией разборщика (`run_iec_checker.py --checker`; по умолчанию `nightly` с `--docker`,
иначе `v0.4`).

## Адаптированный код (`targets/astra/`)

Код флагмана и библиотеки перенесён без правок (метрики — [port_metrics.md](port_metrics.md)), поэтому
и находки iec_checker те же, что в их репозиториях. Файлы обоснований — копии файлов оригиналов с тех
же коммитов, что снимки `upstream/`:

| Файл | Копия | Свои записи |
|---|---|---|
| `targets/astra/iec_checker_allow.toml` | `tools/check/iec_checker_allow.toml` флагмана kns-pump-station, коммит `505ce14` | три записи для объектов сборки REGUL (ниже) |
| `targets/astra/lib/iec_checker_allow.toml` | `tools/check/iec_checker_allow.toml` библиотеки plc-process-lib, тег `v1.0.0` | нет |

Разбор находок оригиналов — в `docs/STATIC_ANALYSIS.md` флагмана и библиотеки. При переносе дельты
оригинала (`tools/upstream_delta.py`) копии сверяют с оригиналом вместе с кодом.

RuSTy по `targets/astra/` не запускается: `run_rusty.py` анализирует `src/` и `tests/`, а у оригиналов
та же проверка — в их CI.

## Последний прогон

| Дата | Инструмент | Вход | Итог |
|---|---|---|---|
| 2026-10-19 | `st_lint --strict` | `src/`, `tests/`, `targets/astra/src/`, `targets/astra/lib/src/` (545 файлов) | 0 ошибок, 0 предупреждений |
| 2026-10-19 | `run_iec_checker.py` (iec_checker 0.4, Windows, локально) | `targets/astra` — 88 объектов | необоснованных 0, обоснованных 1683 |
| 2026-10-19 | `run_iec_checker.py` (iec_checker 0.4, Windows, локально) | `targets/astra/lib` — 79 объектов | необоснованных 0, обоснованных 1072 |
| 2026-10-19 | `run_iec_checker.py --tests` (iec_checker 0.4, Windows, локально) | `src/`, `tests/` — 0 объектов | необоснованных 0, обоснованных 0 |

## Находки

Объекты сборки REGUL (`targets/astra/src/POUs/Regul/`) — все находки iec_checker 0.4 обоснованы в
`targets/astra/iec_checker_allow.toml`:

| Правило | Где | Решение |
|---|---|---|
| PLCOPEN-L17 (IF без ELSE) | `F_MbStatusOk_Regul`, `PRG_ModbusMap_Regul` | ветка «иначе» не нужна: в функции результат `FALSE` присвоен до IF (значение вне диапазона — потеря связи), в программе IF — ранний выход в имитации |
| PLCOPEN-CP9 (сложность) | `PRG_ModbusMap_Regul` | линейное копирование регистров трёх ПЧ и TT403 (имена у каждого насоса свои), одно ветвление; McCabe iec_checker 0.4 завышен — как у `PRG_FieldIn` флагмана |
| UnusedVariable | `PRG_ModbusMap_Regul`: `eP10nStatus`, `eTT403Status`, `uTT403` | ложное срабатывание: статусы — аргументы `TO_INT` внутри вызова `F_MbStatusOk_Regul`, объединение — обращения к полям `dwValue`, `rValue` |
