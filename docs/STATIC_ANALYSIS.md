# Статический анализ

Находки `iec_checker` по `build/assembled/` (и `st_lint` по раскладке), которые не исправлены в коде, —
с обоснованием. Исправленные находки сюда не пишутся. Здесь же — итог проверки компиляции RuSTy.

**Сейчас анализировать нечего.** В `src/` и `tests/` этого репозитория кода нет: пример шаблона удалён,
а адаптированный код для Astra.IDE появится в `targets/astra/` на этапе 2 (README, «Статус»). Находки и
обоснования примера шаблона удалены вместе с ним (`tools/check/iec_checker_allow.toml` пуст).

## Как запускается

| Инструмент | Где | Вход | Отчёт |
|---|---|---|---|
| `tools/check/st_lint.py --strict` | локально и в CI | `src/`, `tests/` | вывод в консоль, код выхода ≠ 0 при нарушениях |
| `tools/check/run_iec_checker.py --tests` | локально и в CI (обязательно): бинарник iec_checker v0.4 из релизов github.com/jubnzv/iec-checker | `build/assembled/iec-checker/` (вариант сборки `iec-checker`) | `build/iec_checker.json`, `build/iec_checker.md` |
| то же с `--docker` | CI, необязательное задание: образ `jubnzv1/iec-checker:nightly`, закреплённый по дайджесту в `ci.yml` | то же | то же, артефакт `iec-checker-nightly-reports` |
| `tools/check/run_rusty.py` | локально и в CI (необязательное задание): RuSTy `plc --check` | `build/assembled/rusty/` (вариант сборки `rusty`, `src/` и `tests/`) | `build/rusty.log`, `build/rusty.json` |
| `tools/check/st_lint.py --strict targets/astra/src targets/astra/tests` | CI, шаг «Код для Astra.IDE», когда каталог появится | адаптированный код | вывод в консоль |

Обоснования в `tools/check/iec_checker_allow.toml` подбираются под находки v0.4 — той же версии, что в
обязательном шаге CI. `run_iec_checker.py` и `run_rusty.py` (инструменты шаблона) анализируют `src/` и
`tests/`; как проверять ими `targets/astra/`, решается на этапе 2 вместе с первым адаптированным кодом.

## Последний прогон

| Дата | Инструмент | Вход | Итог |
|---|---|---|---|
| 2026-10-19 | `st_lint --strict` | `src/`, `tests/` (0 файлов) | 0 ошибок, 0 предупреждений |
| 2026-10-19 | `run_iec_checker.py --tests` (iec_checker 0.4, Windows, локально) | 0 объектов | необоснованных 0, обоснованных 0, неиспользованных обоснований нет |
| 2026-10-19 | `run_rusty.py` (RuSTy 1.0.6, `plc --check`, Windows, локально) | 0 файлов | ошибок 0 |

## Находки

_Нет._
