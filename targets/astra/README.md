# Перенос на Astra.IDE: адаптированный код

Код флагмана КНС-1 и библиотеки plc-process-lib для Astra.IDE (РегЛаб, ПЛК REGUL R500, ВПЛК).
Раскладка та же, что у оригиналов ([docs/LAYOUT.md](../../docs/LAYOUT.md)): один объект — один файл
или папка. Собирается в Astra.IDE скриптом без интерфейса или вручную в среде; сообщения среды —
в [docs/BUILD_ERRORS.md](../../docs/BUILD_ERRORS.md).

**Статус (19.10.2026): компилируется в Astra.IDE 1.7.2.2 без ошибок и предупреждений; на ПЛК и ВПЛК не
запускался.** Библиотека `PL` собрана и установлена в репозиторий библиотек Astra.IDE, приложение
проверено целиком и собрано с «Генерировать код» на REGUL R500 61 и R500 71-W — в сборке для ПЛК и в
сборке ВПЛК ([ниже](#сборка-в-astraide-19102026)). Две итерации, одна правка кода (BUILD_ERRORS 1.1);
журнал — [docs/BUILD_ERRORS.md](../../docs/BUILD_ERRORS.md). Кроме того, код проверен линтером,
статанализом iec_checker 0.4 и конвертером PLCopen XML (схема TC6 2.01).

## С каких коммитов сделан перенос

| Дерево | Оригинал | Ревизия | Коммит | Снимок оригинала |
|---|---|---|---|---|
| [`src/`](src/) — приложение КНС-1 | [kns-pump-station](https://github.com/kr0nsch/kns-pump-station), `src/` | `main` | `505ce149a0e0fb72b5cce79e72876722abeba9d0` (19.10.2026) | [`upstream/kns-pump-station/src`](../../upstream/kns-pump-station/src) |
| [`lib/src/`](lib/src/) — библиотека `PL` | [plc-process-lib](https://github.com/kr0nsch/plc-process-lib), `src/` без `PRG_Main` | тег `v1.0.0` | `bd9df2a4c0266b7d4992763d5151f21cae490609` (19.10.2026) | [`upstream/plc-process-lib/src`](../../upstream/plc-process-lib/src) |

Машиночитаемая запись — [`upstream/SOURCES.json`](../../upstream/SOURCES.json). Снимок — дерево `src`
коммита как есть; плейсхолдеры портфолио (имя автора в заголовках POU) заменены, как во всём репозитории. От
снимка считаются метрики переноса и дельта при обновлении флагмана (ниже).

`PRG_Main` библиотеки — программа её рабочей сборки, в библиотеку не входит (`library.exclude` в
`tools/codesys/config.json` библиотеки), поэтому не перенесена. Тесты coUnit не переносятся: сборка
coUnit в Astra.IDE не подтверждена (пункт H2 чек-листа); пока юнит-тесты логики идут в CODESYS
3.5.17.30 в репозиториях оригиналов ([ASSUMPTIONS.md](../../docs/ASSUMPTIONS.md#этап-2-адаптированный-код), P11).

## Что изменено

Объём — [docs/port_metrics.md](../../docs/port_metrics.md): все 10 874 значимые строки оригинала
перенесены без изменений, добавлены 3 объекта (68 строк). Маркеры `// PORT:` двух видов:

| Вид | Сколько | Что значит |
|---|---:|---|
| `// PORT: [категория] причина` — правка | 4 | код изменён или добавлен; категория — за что заплачено. Четвёртый маркер — правка по сборке (BUILD_ERRORS 1.1) |
| `// PORT: [категория] проверить в Astra.IDE — что (пункт)` — проверка | 58 | код оставлен в форме CODESYS: поведение Astra.IDE не подтверждено, пункт — раздел 9 [чек-листа](../../docs/migration_checklist.md#9-проверить-вручную). До сборки их было 283; 225 сняты 19.10.2026 по пунктам, которые подтвердила компиляция (C1–C5, C7, C13, D1). Остались C11 (`LTIME`, 46 — монотонность `LTIME()` проверяется онлайн), C10 (CAA File, 5), C15, B3, D4 (по 1), E2, G4 (по 2) |

Маркеры проверки по правилам расставляет `tools/port_checks.py` (правила — в начале файла, решения по
пунктам — [`port_checks.json`](port_checks.json)); шесть маркеров поставлены вручную: OPC UA (G4,
два), путь CSV (C10), запись PERSISTENT (D4), статус канала Modbus (E2, два).

Новые объекты — только для сборки на реальном ПЛК REGUL (`src/POUs/Regul/`, `src/GVLs/Regul/`):

| Объект | Зачем |
|---|---|
| `PRG_ModbusMap_Regul` | слой Modbus RTU: массивы WORD каналов `Modbus Serial Outer Slave` ↔ регистры `GVL_IO` (ПЧ Н1…Н3 — FC3 4x 100…103 и FC16 4x 0…1, TT403 — FC4 3x 0…1, REAL HL), признаки обмена `GVL_IO.xMbOk_*` по статусу каналов чтения (тип `PsIoDrvModbusSerialMaster.ChannelStatus` — BUILD_ERRORS 1.1). Заменяет мастер Modbus CODESYS и диагностику слейвов. В имитации сразу выходит |
| `F_MbStatusOk_Regul` | статус канала `ChannelStatus` (0…6) → «обмен исправен» по таблице `GVL_ConstRegul.MB_STATUS_OK` |
| `GVL_ConstRegul` | раскладка массивов каналов и таблица статусов. Какие значения `ChannelStatus` означают «обмен исправен», в документации нет: до проверки (E2) все `FALSE` — адаптер показывает потерю связи, станция работает по ступеням, насосы — проводами |

## Две сборки

| | ВПЛК REGUL R500 (испытания по ПМИ) | ПЛК REGUL R500 (объект) |
|---|---|---|
| `GVL_Const.SIM_ALLOWED` | `TRUE`, как в коде (имитация разрешена) | `FALSE` — правка константы в проекте, как у сборки ПЛК210 флагмана |
| `GVL_Sim.xSimulationReq` | `TRUE` | `FALSE` |
| `MainTask`, 20 мс | `PRG_FieldIn`, `PRG_DeviceList`, `PRG_Station`, `PRG_Devices`, `PRG_FieldOut` | первой — `PRG_ModbusMap_Regul`, затем те же |
| `PlantModelTask`, 20 мс | `PRG_PlantModel` | нет |
| `SlowTask`, 200 мс | `PRG_Slow` | `PRG_Slow` |
| Ввод-вывод | модель объекта (на ВПЛК нет RegulBus и Modbus RTU [F69]) | модули RegulBus → `GVL_IO`, устройства Modbus → `PRG_ModbusMap_Regul` |
| Библиотеки | `PL`, Standard, CAA File, SysTimeRtc | те же и `PsIoDrvModbusSerialMaster` (её добавляет устройство Modbus Serial Master) |
| Сборка в Astra.IDE 1.7.2.2, 19.10.2026 | R500 71-W и R500 61: 0 ошибок, 0 предупреждений, «Генерировать код» — готово к загрузке | R500 61 и R500 71-W: 0 ошибок, 0 предупреждений, «Генерировать код» — готово к загрузке |

Приоритеты задач в диапазоне REGUL (5, 6, 14, `VISU_TASK` — 15) и прочие ручные шаги — разделы 1–5
[чек-листа](../../docs/migration_checklist.md).

## Сборка в Astra.IDE (19.10.2026)

Astra.IDE 1.7.2.2 (профиль `Astra.IDE_V1.7.2.2`, описания устройств REGUL 11.7.2.60), сборка скриптом без
интерфейса среды; подробно, с сообщениями компилятора, — [BUILD_ERRORS.md](../../docs/BUILD_ERRORS.md).

| Что | Устройство | Ошибок | Предупреждений |
|---|---|---:|---:|
| библиотека `PL` 1.0.0.0: проверка всех 79 объектов, установка `.compiled-library` в репозиторий `System` | — | 0 | 0 |
| приложение: проверка всех 88 объектов (`cds.py check`) | R500 61, R500 71-W | 0 | 0 |
| сборка для ПЛК: «Сборка» и «Генерировать код» | R500 61, R500 71-W | 0 | 0 |
| сборка ВПЛК: «Сборка» и «Генерировать код» | R500 71-W, R500 61 | 0 | 0 |

| Итерация | Ошибок | Что было | Исправление |
|---|---:|---|---|
| 1 | 8 и 1 предупреждение | `PsModbusSerialMaster.ChannelStatus` не найден (C0077, следом C0032) в `PRG_ModbusMap_Regul`; C0100 о CmpCodeMeter — только вместе с ними | тип из пространства имён библиотеки драйвера `PsIoDrvModbusSerialMaster` (`45550e8`) |
| 2 и итог | 0 | — | — |

Что подтвердила компиляция: наследование ФБ и интерфейсов, `SUPER^`, `THIS^`, `ABSTRACT`, спецификаторы
доступа и свойства, `strict` (зонд), перечисления с базовым типом, `VAR_IN_OUT CONSTANT`, Persistent
Variables, сборка только достижимых из задач объектов (C16) — пункты C1–C5, C7, C13, C16, D1, а также
A4 (библиотеки) и A5 (скриптовый движок). Компиляция — не исполнение: на ПЛК и ВПЛК код не загружался,
поэтому не проверены время `LTIME()` (C11), запись CSV (C10), метки UTC (C15), RETAIN и PERSISTENT
(D2–D4), Modbus (E1–E7), OPC UA (G1–G5), визуализация (F1–F4) и вся ПМИ.

## Как собрать в Astra.IDE (инженер)

**Без интерфейса (скриптом), как 19.10.2026.** `tools/codesys/cds.py` работает с Astra.IDE без правок —
переменные окружения, рабочие каталоги и `config.json` сборок — в
[BUILD_ERRORS.md](../../docs/BUILD_ERRORS.md#сборка-без-интерфейса): библиотека — `cds.py library
--compiled --install` по `targets/astra/lib/src`, приложение — `cds.py check` и `cds.py build` по
`targets/astra/src`, затем «Генерировать код».

**В среде вручную:**

1. Файлы импорта (их же собирает CI в артефакт `build-reports`):

   ```bash
   python tools/st_to_plcopen.py --root targets/astra/lib --name plc-process-lib --out build/plcopen/astra-lib.xml --xsd auto
   python tools/st_to_plcopen.py --root targets/astra --name kns-pump-station --out build/plcopen/astra-app.xml --xsd auto
   ```

2. Библиотека: проект-библиотека Astra.IDE, импорт `astra-lib.xml`, пространство имён `PL`, сборка,
   установка в репозиторий библиотек (или установить `.library`, собранную в CODESYS 3.5.17.30, — A7).
3. Приложение: проект мастером Regul (R500, ЦП CU 00 071-W), библиотеки `PL`, Standard, CAA File,
   SysTimeRtc; импорт `astra-app.xml`; задачи — по таблице выше; «Очистить всё», «Генерировать код».
4. Сообщения — в [BUILD_ERRORS.md](../../docs/BUILD_ERRORS.md) (новая итерация). По каждому пункту
   «проверить вручную», который сборка подтвердила или опровергла, — решение в `port_checks.json`:

   ```bash
   python tools/port_checks.py --resolve C11 --note "ГГГГ-ММ-ДД, Astra.IDE 1.7.2.2, ВПЛК: LTIME() монотонно (протокол ПМИ)"
   python tools/port_checks.py --fail C10 --note "BUILD_ERRORS N.k: CAA File не пишет CSV на ВПЛК"
   ```

   `--resolve` снимает маркеры пункта; `--fail` превращает каждое место конструкции в ошибку
   `port_checks --strict`, пока код не переписан (правки — с маркерами `// PORT: [категория]
   BUILD_ERRORS N.k: …`).

## Когда флагман или библиотека обновились

Флагман ещё получает исправления. Дельта переносится так:

```bash
python tools/upstream_delta.py kns-pump-station --to main          # что изменилось и что делать с копиями
python tools/upstream_delta.py kns-pump-station --to main --apply  # записать, снимок → новый коммит
python tools/port_checks.py --fix                                  # маркеры проверки у новых конструкций
python tools/port_metrics.py --strict                              # метрики и проверка пометок
python tools/check/st_lint.py --strict                             # линтер
```

`upstream_delta.py` сравнивает снимок `upstream/<id>/src` с деревом нового коммита (из рабочей копии
оригинала рядом, `../kns-pump-station` или переменная `KNS_REPO`) и для каждого изменённого файла
смотрит копию в `targets/astra/`:

| Копия в переносе | Действие |
|---|---|
| совпадает со снимком (не правилась) | заменить новой версией |
| правилась (маркеры, правки) | трёхстороннее слияние `git merge-file`: без конфликтов — правки переноса сохраняются; с конфликтом — файл записывается с маркерами `<<<<<<< перенос … >>>>>>> стало`, разобрать вручную |
| файла нет, в оригинале добавлен | скопировать |
| в оригинале удалён | удалить, если в переносе не правился; иначе — решить вручную |

Таблицу без `--apply` можно сохранить (`--md файл`) и приложить к коммиту. После `--apply` снимок и
коммит в `upstream/SOURCES.json` указывают на новую версию оригинала; пока в переносе остаются маркеры
конфликта, следующий `--apply` отказывается. Ревизии в `tools/inventory.toml` меняют на новые коммиты и
пересобирают `docs/inventory.md`; копии обоснований iec_checker (`iec_checker_allow.toml` здесь и в
`lib/`) сверяют с оригиналом. `python tools/upstream_delta.py --verify` проверяет, что снимки совпадают
с записанными коммитами.

## Проверки без Astra.IDE

| Проверка | Команда | Итог (19.10.2026, после сборки в Astra.IDE) |
|---|---|---|
| линтер ST | `python tools/check/st_lint.py --strict` | 545 файлов, 0 ошибок |
| маркеры проверки | `python tools/port_checks.py --strict` | 277 мест по правилам; у мест открытых пунктов (B3, C10, C11, C15) — 52 маркера, с ручными — 58; лишних нет |
| метрики, пометка правок | `python tools/port_metrics.py --check --strict` | отчёт актуален, правок без маркера 0 |
| PLCopen XML | команды выше | 88 и 79 объектов, схема TC6 2.01 — без ошибок |
| iec_checker 0.4 (приложение) | `python tools/check/run_iec_checker.py --root targets/astra --allow targets/astra/iec_checker_allow.toml` | 88 файлов, необоснованных 0 |
| iec_checker 0.4 (библиотека) | `python tools/check/run_iec_checker.py --root targets/astra/lib --allow targets/astra/lib/iec_checker_allow.toml` | 79 файлов, необоснованных 0 |

Обоснования iec_checker — копии файлов оригиналов (код перенесён без правок, находки те же) и три
записи для объектов сборки REGUL; разбор — [docs/STATIC_ANALYSIS.md](../../docs/STATIC_ANALYSIS.md).
