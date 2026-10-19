#!/usr/bin/env python3
"""Эталонная проверка tools/st_to_plcopen.py в CODESYS 3.5.17.30: XML -> импорт -> сборка -> сравнение.

Для каждой раскладки (`--case ИМЯ=КОРЕНЬ`, в корне — каталог `src/`) и каждого пространства имён TC6
(`--namespace`, по умолчанию tc6_0201 и tc6_0200):

1. `st_to_plcopen.py` пишет `build/plcopen/verify/<случай>-<ns>.xml`;
2. CODESYS (`--noUI`, скрипт `cds_import_check.py`) импортирует файл в пустой проект двумя способами:
   `app` — в приложение проекта с устройством (Control Win V3, `DeviceID(4096, '0000 0001', '3.5.17.30')`),
   задача MainTask -> PRG_Main (если такая программа есть), `app.rebuild()`;
   `pool` — в пул POU проекта без устройства, «Проверить все объекты пула» (компилируется всё, даже то,
   что никто не вызывает);
3. дерево импортированных объектов сравнивается с раскладкой: каждый объект, метод, свойство, аксессор
   и папка на месте, тексты объявлений и тел совпадают с файлами (после нормализации stlayout);
4. итог — таблица в консоли, `build/plcopen/verify.json` и `build/plcopen/verify.md`.

Без аргументов проверяются фикстура всех конструкций `tools/plcopen/tests/fixtures/constructs` и
исходники библиотеки `plc-process-lib` (переменная `PL_REPO`, по умолчанию соседний каталог
`../plc-process-lib`; берётся та ветка, что в нём выгружена). Библиотеки проекта — Standard через
плейсхолдер, как у `cds.py` (описание `standard` из `tools/codesys/config.json`).

Коды выхода: 0 — всё импортировано без потерь и собрано без ошибок; 1 — есть потери, расхождения
текстов или ошибки компиляции; 2 — аргументы; 3 — окружение (нет CODESYS, ошибка скрипта CODESYS);
4 — таймаут CODESYS.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from collections.abc import Iterable, Mapping, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

PLCOPEN_DIR = Path(__file__).resolve().parent
TOOLS_DIR = PLCOPEN_DIR.parent
REPO_ROOT = TOOLS_DIR.parent
for _path in (TOOLS_DIR, TOOLS_DIR / "codesys"):
    if str(_path) not in sys.path:
        sys.path.insert(0, str(_path))

import st_to_plcopen as S  # noqa: E402
import stlayout as L  # noqa: E402
from cdshost import cli  # noqa: E402

SCRIPT = PLCOPEN_DIR / "cds_import_check.py"
FIXTURE = PLCOPEN_DIR / "tests" / "fixtures" / "constructs"
OUT_DIR = REPO_ROOT / "build" / "plcopen"
MODES = ("app", "pool")
ERROR_SEVERITIES = ("Error", "FatalError")
WARNING_SEVERITIES = ("Warning",)
TIMESTAMP = "2026-01-01T00:00:00"

EXIT_OK = 0
EXIT_FAILED = 1
EXIT_USAGE = 2
EXIT_ENV = 3
EXIT_TIMEOUT = 4


# ---------------------------------------------------------------------------
# Ожидаемое дерево объектов по раскладке
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Expected:
    """Объект CODESYS, который должен появиться после импорта: путь от приложения или пула, вид, тексты."""

    path: tuple[str, ...]
    kind: str
    decl: str | None = None
    impl: str | None = None


def expected_objects(objects: Iterable[L.StObject]) -> list[Expected]:
    """Папки, объекты, методы, свойства и аксессоры раскладки — как их показывает дерево CODESYS."""
    found: list[Expected] = []
    folders: set[tuple[str, ...]] = set()
    for obj in objects:
        for depth in range(1, len(obj.folder) + 1):
            key = tuple(obj.folder[:depth])
            if key not in folders:
                folders.add(key)
                found.append(Expected(key, "folder"))
        base = (*obj.folder, obj.name)
        is_itf = obj.kind == L.KIND_ITF
        found.append(Expected(base, obj.kind, obj.decl, None if obj.kind != L.KIND_POU else (obj.impl or "")))
        for method in obj.methods:
            impl = None if is_itf else (method.impl or "")
            found.append(Expected((*base, method.name), "method", method.decl, impl))
        for prop in obj.properties:
            found.append(Expected((*base, prop.name), "property", prop.decl, None))
            for present, accessor, decl, impl in (
                (prop.has_get, "Get", prop.get_decl, prop.get_impl),
                (prop.has_set, "Set", prop.set_decl, prop.set_impl),
            ):
                if not present:
                    continue
                if is_itf:
                    found.append(Expected((*base, prop.name, accessor), "accessor", decl or "", None))
                else:
                    text = decl if decl is not None else S.DEFAULT_ACCESSOR_DECL
                    found.append(Expected((*base, prop.name, accessor), "accessor", text, impl or ""))
    return found


# ---------------------------------------------------------------------------
# Сравнение с деревом CODESYS
# ---------------------------------------------------------------------------


@dataclass
class Comparison:
    """Итог сравнения дерева CODESYS с раскладкой."""

    expected: int = 0
    found: int = 0
    missing: list[str] = field(default_factory=list)
    extra: list[str] = field(default_factory=list)
    kind_mismatch: list[str] = field(default_factory=list)
    text_mismatch: list[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not (self.missing or self.extra or self.kind_mismatch or self.text_mismatch)


def _same_text(actual: Any, expected: str | None) -> bool:
    if expected is None:
        return True
    return L.normalize_text(str(actual or "")) == L.normalize_text(expected)


def _first_difference(actual: str, expected: str) -> str:
    """Первая отличающаяся строка: «строка N: CODESYS '...' / файл '...'»."""
    got = L.normalize_text(actual).split("\n")
    want = L.normalize_text(expected).split("\n")
    for index in range(max(len(got), len(want))):
        left = got[index] if index < len(got) else "<нет строки>"
        right = want[index] if index < len(want) else "<нет строки>"
        if left != right:
            return f"строка {index + 1}: CODESYS {left!r} / файл {right!r}"
    return "различие в пробельных символах"


def compare(expected: Sequence[Expected], dumped: Sequence[Mapping[str, Any]]) -> Comparison:
    """Дерево CODESYS (dump скрипта cds_import_check.py) против ожидаемого по раскладке."""
    result = Comparison(expected=len(expected), found=len(dumped))
    by_path = {tuple(item["path"]): item for item in dumped}
    wanted = {item.path for item in expected}
    for item in expected:
        label = ".".join(item.path)
        got = by_path.get(item.path)
        if got is None:
            result.missing.append(f"{label} ({item.kind})")
            continue
        if got.get("kind") != item.kind:
            result.kind_mismatch.append(f"{label}: в CODESYS {got.get('kind')}, ожидался {item.kind}")
            continue
        for what, want in (("объявление", item.decl), ("тело", item.impl)):
            have = got.get("decl" if what == "объявление" else "impl")
            if not _same_text(have, want):
                diff = _first_difference(str(have or ""), want or "")
                result.text_mismatch.append(f"{label}: {what}: {diff}")
    for path, got in by_path.items():
        if path not in wanted:
            result.extra.append(f"{'.'.join(path)} ({got.get('kind')})")
    return result


def compiler_errors(messages: Sequence[Mapping[str, Any]]) -> list[str]:
    return [_format_message(m) for m in messages if m.get("severity") in ERROR_SEVERITIES]


def compiler_warnings(messages: Sequence[Mapping[str, Any]]) -> list[str]:
    return [_format_message(m) for m in messages if m.get("severity") in WARNING_SEVERITIES]


def _format_message(msg: Mapping[str, Any]) -> str:
    where = ""
    if msg.get("object"):
        position = f", {msg['position']}" if msg.get("position") else ""
        where = f" [{msg['object']}{position}]"
    code = f"{msg['code']} " if msg.get("code") else ""
    return f"{msg.get('severity')} {code}{msg.get('text')}{where}"


# ---------------------------------------------------------------------------
# Случаи проверки
# ---------------------------------------------------------------------------


@dataclass
class Case:
    """Раскладка и пространство имён: файл XML для приложения (app) и для пула POU (pool).

    В пуле POU нет приложения, а Persistent Variables бывают только в приложении («Невозможно вставить
    'PersistentVars' под '<root>'», проверено на 3.5.17.30). Поэтому для режима pool раскладка с PVL
    преобразуется в отдельный файл, где PVL — обычный GVL с тем же текстом без слова PERSISTENT
    (так же делает `cds.py check`); без PVL оба режима берут один файл.
    """

    name: str
    root: Path
    namespace: str
    xml: Path
    objects: list[L.StObject] = field(default_factory=list)
    task: str | None = None
    conversion_issues: list[S.Issue] = field(default_factory=list)
    plaintext: bool = True
    pool_xml: Path | None = None
    pool_objects: list[L.StObject] | None = None

    def xml_for(self, mode: str) -> Path:
        return self.pool_xml if mode == "pool" and self.pool_xml is not None else self.xml

    def objects_for(self, mode: str) -> list[L.StObject]:
        return self.pool_objects if mode == "pool" and self.pool_objects is not None else self.objects

    @property
    def label(self) -> str:
        """Вариант файла: пространство имён и «tc6-only» для файла без текстов объявлений."""
        return self.namespace if self.plaintext else f"{self.namespace}-tc6only"


@dataclass
class CaseReport:
    """Итог одного прогона: импорт, сравнение, компиляция."""

    case: str
    namespace: str
    mode: str
    xml: str
    import_errors: list[str]
    import_warnings: list[str]
    comparison: Comparison
    errors: list[str]
    warnings: list[str]
    summary_line: str | None
    failure: str | None = None
    roundtrip: list[str] | None = None
    informational: bool = False

    @property
    def verdict(self) -> str:
        """OK / ОШИБКА; у файла без текстов объявлений (--structural) — OK / «потери TC6» (для сведения)."""
        if self.ok:
            return "OK"
        return "потери TC6" if self.informational else "ОШИБКА"

    @property
    def ok(self) -> bool:
        clean = self.failure is None and not self.import_errors and self.comparison.ok and not self.errors
        return clean and not self.roundtrip


def parse_case(text: str) -> tuple[str, Path]:
    name, sep, root = text.partition("=")
    if not sep or not name or not root:
        raise ValueError(f"--case {text!r}: нужен вид ИМЯ=КОРЕНЬ_РАСКЛАДКИ")
    return name, Path(root)


def default_cases(environ: Mapping[str, str]) -> list[tuple[str, Path]]:
    cases = [("constructs", FIXTURE)]
    lib = Path(environ.get("PL_REPO") or (REPO_ROOT.parent / "plc-process-lib"))
    if (lib / "src").is_dir():
        cases.append(("plc-process-lib", lib))
    return cases


def pvl_as_gvl(obj: L.StObject) -> L.StObject:
    """PVL -> GVL с тем же текстом без слова PERSISTENT (для пула POU); прочие объекты — как есть."""
    if obj.kind != L.KIND_PVL:
        return obj
    decl = re.sub(r"\s+PERSISTENT\b", "", obj.decl, flags=re.IGNORECASE)
    return L.StObject(L.KIND_GVL, obj.name, decl, obj.folder, subdir=obj.subdir)


def _convert(name: str, placed: list[tuple[L.StObject, list[str]]], options: S.Options, xml: Path) -> S.Result:
    result = S.convert_objects(placed, options)
    if result.errors:
        raise ValueError(f"{name}: ошибки преобразования:\n" + "\n".join(i.format() for i in result.errors))
    xml.parent.mkdir(parents=True, exist_ok=True)
    xml.write_text(result.xml, encoding="utf-8", newline="\n")
    return result


def prepare(name: str, root: Path, namespace: str, out_dir: Path, plaintext: bool = True) -> Case:
    """XML из раскладки root/src в out_dir/<имя>-<ns>[-tc6only].xml; ошибки раскладки — ValueError."""
    ns_label = namespace.replace("tc6_", "") + ("" if plaintext else "-tc6only")
    xml = out_dir / f"{name}-{ns_label}.xml"
    options = S.Options(namespace=S.NAMESPACES[namespace], project_name=name, timestamp=TIMESTAMP, plaintext=plaintext)
    placed, issues = S.collect_objects(str(root), [("src", [])])
    if any(i.severity == "error" for i in issues):
        raise ValueError(f"{name}: ошибки раскладки:\n" + "\n".join(i.format() for i in issues))
    result = _convert(name, placed, options, xml)
    objects = [obj for obj, _ in placed]
    task = next((o.name for o in objects if o.kind == L.KIND_POU and o.name == "PRG_Main"), None)
    case = Case(name, root, namespace, xml, objects, task, [*issues, *result.issues], plaintext)
    if any(obj.kind == L.KIND_PVL for obj in objects):
        pool_placed = [(pvl_as_gvl(obj), folder) for obj, folder in placed]
        case.pool_xml = xml.with_name(f"{xml.stem}-pool.xml")
        _convert(name, pool_placed, options, case.pool_xml)
        case.pool_objects = [obj for obj, _ in pool_placed]
    return case


def export_path(case: Case, out_dir: Path) -> str:
    """Экспорт CODESYS приложения после импорта (режим app) — для обратной проверки."""
    return str(out_dir / "export" / f"{case.xml.stem}-codesys.xml")


def roundtrip_differences(source: Sequence[L.StObject], exported: Sequence[L.StObject]) -> list[str]:
    """Файлы раскладки из экспорта CODESYS против исходных: путь и первая отличающаяся строка."""

    def files(objects: Sequence[L.StObject]) -> dict[str, str]:
        return {path: text for obj in objects for path, text in L.object_files(obj, "src")}

    want = files(source)
    got = files(exported)
    found: list[str] = []
    for path in sorted(set(want) | set(got)):
        if path not in got:
            found.append(f"{path}: нет в экспорте CODESYS")
        elif path not in want:
            found.append(f"{path}: лишний файл из экспорта CODESYS")
        elif got[path] != want[path]:
            found.append(f"{path}: {_first_difference(got[path], want[path])}")
    return found


def check_export(path: str, source: Sequence[L.StObject]) -> list[str]:
    """Экспорт CODESYS -> раскладка (st_to_plcopen.read_xml) -> сравнение с исходной раскладкой."""
    try:
        text = Path(path).read_text(encoding="utf-8-sig")
        objects, issues = S.read_xml(text)
    except (OSError, ET.ParseError) as exc:
        return [f"экспорт CODESYS {path}: {exc}"]
    problems = [i.format() for i in issues if i.severity == "error"]
    return problems + roundtrip_differences(source, objects)


def build_job(cases: Sequence[Case], settings: cli.Settings, out_dir: Path) -> dict[str, Any]:
    job_cases = []
    for case in cases:
        for mode in MODES:
            job_cases.append(
                {
                    "name": f"{case.name}-{case.label}-{mode}",
                    "xml": str(case.xml_for(mode)),
                    "mode": mode,
                    "project": str(out_dir / "projects" / f"{case.xml.stem}-{mode}.project"),
                    "task": case.task,
                    "export": export_path(case, out_dir) if mode == "app" and case.plaintext else None,
                }
            )
    return {
        "tools_codesys": str(TOOLS_DIR / "codesys"),
        "device": settings.device(),
        "libraries": [settings.library_spec("standard")],
        "repository": "System",
        "result": str(out_dir / "verify-result.json"),
        "log": str(out_dir / "verify-codesys.log"),
        "cases": job_cases,
    }


def run_codesys(job: Mapping[str, Any], settings: cli.Settings, out_dir: Path, timeout_s: float) -> dict[str, Any]:
    """Запуск CODESYS со скриптом и файлом задания; результат — JSON скрипта."""
    job_path = out_dir / "verify-job.json"
    job_path.write_text(json.dumps(job, ensure_ascii=False, indent=2), encoding="utf-8", newline="\n")
    result_path = Path(str(job["result"]))
    if result_path.exists():
        result_path.unlink()
    cmd = cli.build_cmdline(settings.codesys_exe, settings.profile, SCRIPT)
    env = dict(os.environ)
    env["CDS_JOB"] = str(job_path)
    proc = subprocess.run(cmd, env=env, capture_output=True, timeout=timeout_s, check=False)
    (out_dir / "verify-codesys.stdout.log").write_bytes(proc.stdout + proc.stderr)
    if not result_path.exists():
        raise RuntimeError(f"CODESYS завершился с кодом {proc.returncode} без файла результата {result_path}")
    data: dict[str, Any] = json.loads(result_path.read_text(encoding="utf-8"))
    if data.get("error"):
        raise RuntimeError(f"скрипт CODESYS: {data['error']}")
    return data


def evaluate(cases: Sequence[Case], data: Mapping[str, Any]) -> list[CaseReport]:
    by_name = {c["name"]: c for c in data.get("cases", [])}
    reports: list[CaseReport] = []
    for case in cases:
        for mode in MODES:
            expected = expected_objects(case.objects_for(mode))
            if not case.plaintext:
                # без текстов объявлений CODESYS строит их из структуры TC6: сверяются только объекты и виды
                expected = [Expected(e.path, e.kind) for e in expected]
            raw = by_name.get(f"{case.name}-{case.label}-{mode}", {})
            messages = raw.get("import_messages", [])
            import_errors = [m["text"] for m in messages if m.get("level") in ("error", "skipped", "conflict")]
            if raw.get("import_exception"):
                import_errors.append(f"исключение импорта: {raw['import_exception']}")
            import_warnings = [m["text"] for m in messages if m.get("level") == "warning"]
            records = raw.get("messages", [])
            summary = raw.get("summary") or {}
            failure = raw.get("error") if raw else "нет результата CODESYS для случая"
            roundtrip = None
            if raw.get("export"):
                roundtrip = check_export(raw["export"], case.objects_for(mode))
            elif raw.get("export_error"):
                roundtrip = [f"экспорт CODESYS не удался: {raw['export_error']}"]
            reports.append(
                CaseReport(
                    case=case.name,
                    namespace=case.label,
                    mode=mode,
                    xml=str(case.xml_for(mode)),
                    import_errors=import_errors,
                    import_warnings=import_warnings,
                    comparison=compare(expected, raw.get("objects", [])),
                    errors=compiler_errors(records),
                    warnings=compiler_warnings(records),
                    summary_line=summary.get("summary_line"),
                    failure=failure,
                    roundtrip=roundtrip,
                    informational=not case.plaintext,
                )
            )
    return reports


# ---------------------------------------------------------------------------
# Отчёт
# ---------------------------------------------------------------------------


def _roundtrip_cell(rep: CaseReport) -> str:
    if rep.roundtrip is None:
        return "—"
    return "совпадает" if not rep.roundtrip else f"расхождений {len(rep.roundtrip)}"


def _problem_count(rep: CaseReport) -> int:
    cmp_ = rep.comparison
    return len(cmp_.missing) + len(cmp_.extra) + len(cmp_.kind_mismatch) + len(cmp_.text_mismatch)


def _details(rep: CaseReport) -> list[str]:
    cmp_ = rep.comparison
    return [
        *([f"сбой: {rep.failure}"] if rep.failure else []),
        *(f"импорт: {t}" for t in rep.import_errors),
        *(f"импорт (предупреждение): {t}" for t in rep.import_warnings),
        *(f"нет в CODESYS: {t}" for t in cmp_.missing),
        *(f"лишнее в CODESYS: {t}" for t in cmp_.extra),
        *(f"другой вид: {t}" for t in cmp_.kind_mismatch),
        *(f"текст: {t}" for t in cmp_.text_mismatch),
        *(f"компилятор: {t}" for t in rep.errors),
        *(f"компилятор: {t}" for t in rep.warnings),
        *(f"экспорт CODESYS -> раскладка: {t}" for t in rep.roundtrip or []),
    ]


def report_lines(reports: Sequence[CaseReport], markdown: bool) -> list[str]:
    """Таблица итогов (Markdown) или строки для консоли, затем подробности по прогонам с замечаниями."""
    lines: list[str] = []
    if markdown:
        lines += [
            "| Раскладка | Вариант XML | Режим | Объектов (ожид. / в CODESYS) | Потери и расхождения текстов | "
            "Ошибок импорта | Ошибок / предупреждений компиляции | Экспорт CODESYS -> раскладка | Итог |",
            "|---|---|---|---|---|---|---|---|---|",
        ]
    for rep in reports:
        cmp_ = rep.comparison
        verdict = rep.verdict
        if markdown:
            lines.append(
                f"| {rep.case} | {rep.namespace} | {rep.mode} | {cmp_.expected} / {cmp_.found} | "
                f"{_problem_count(rep)} | {len(rep.import_errors)} | {len(rep.errors)} / {len(rep.warnings)} | "
                f"{_roundtrip_cell(rep)} | {verdict} |"
            )
        else:
            lines.append(
                f"[verify] {rep.case} {rep.namespace} {rep.mode}: объектов {cmp_.expected}/{cmp_.found}, "
                f"расхождений {_problem_count(rep)}, ошибок импорта {len(rep.import_errors)}, "
                f"компиляция: ошибок {len(rep.errors)}, предупреждений {len(rep.warnings)}, "
                f"экспорт -> раскладка: {_roundtrip_cell(rep)} — {verdict}"
            )
    for rep in reports:
        items = _details(rep)
        if not items:
            continue
        if markdown:
            lines += ["", f"**{rep.case} {rep.namespace} {rep.mode}**", "", *(f"- {t}" for t in items)]
        else:
            lines += [f"{rep.case} {rep.namespace} {rep.mode}:", *(f"  {t}" for t in items)]
    return lines


def to_json(reports: Sequence[CaseReport], cases: Sequence[Case]) -> dict[str, Any]:
    return {
        "codesys": "3.5.17.30",
        "date": time.strftime("%Y-%m-%d"),
        "cases": [
            {
                "case": r.case,
                "namespace": r.namespace,
                "mode": r.mode,
                "xml": os.path.relpath(r.xml, REPO_ROOT),
                "ok": r.ok,
                "informational": r.informational,
                "failure": r.failure,
                "import_errors": r.import_errors,
                "import_warnings": r.import_warnings,
                "expected_objects": r.comparison.expected,
                "codesys_objects": r.comparison.found,
                "missing": r.comparison.missing,
                "extra": r.comparison.extra,
                "kind_mismatch": r.comparison.kind_mismatch,
                "text_mismatch": r.comparison.text_mismatch,
                "compiler_errors": r.errors,
                "compiler_warnings": r.warnings,
                "summary_line": r.summary_line,
                "roundtrip": r.roundtrip,
            }
            for r in reports
        ],
        "conversion_warnings": {
            f"{c.name}-{c.label}": [i.format() for i in c.conversion_issues if i.severity == "warning"] for c in cases
        },
    }


# ---------------------------------------------------------------------------
# Командная строка
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="verify_codesys.py",
        description="Эталонная проверка st_to_plcopen.py: импорт XML в CODESYS 3.5.17.30, сборка, сравнение.",
    )
    parser.add_argument("--case", action="append", default=[], metavar="ИМЯ=КОРЕНЬ", help="раскладка (повтор)")
    parser.add_argument(
        "--namespace",
        action="append",
        choices=sorted(S.NAMESPACES),
        help="пространство имён TC6 (повтор; по умолчанию tc6_0201 и tc6_0200)",
    )
    parser.add_argument(
        "--structural",
        action="store_true",
        help="ещё и файлы без текстов объявлений (--no-plaintext): проверка структурной части TC6",
    )
    parser.add_argument("--out", default=str(OUT_DIR), help="каталог результатов (по умолчанию build/plcopen)")
    parser.add_argument("--timeout", type=float, default=1800.0, help="таймаут CODESYS, с (по умолчанию 1800)")
    parser.add_argument("--dry-run", action="store_true", help="только XML и файл задания, без CODESYS")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    S.configure_output()
    args = build_parser().parse_args(argv)
    try:
        specs = [parse_case(text) for text in args.case] or default_cases(os.environ)
    except ValueError as exc:
        print(exc, file=sys.stderr)
        return EXIT_USAGE
    namespaces = args.namespace or ["tc6_0201", "tc6_0200"]
    out_dir = Path(args.out).resolve()
    xml_dir = out_dir / "verify"
    cases: list[Case] = []
    variants = [True, False] if args.structural else [True]
    for name, root in specs:
        for namespace in namespaces:
            for plaintext in variants:
                try:
                    cases.append(prepare(name, root.resolve(), namespace, xml_dir, plaintext))
                except ValueError as exc:
                    print(exc, file=sys.stderr)
                    return EXIT_FAILED
    try:
        settings = cli.make_settings(REPO_ROOT)
        job = build_job(cases, settings, out_dir)
    except cli.CdsError as exc:
        print(f"[verify] {exc}", file=sys.stderr)
        return EXIT_ENV
    if args.dry_run:
        path = out_dir / "verify-job.json"
        path.write_text(json.dumps(job, ensure_ascii=False, indent=2), encoding="utf-8", newline="\n")
        print(f"[verify] XML: {', '.join(str(c.xml) for c in cases)}; задание: {path}")
        return EXIT_OK
    started = time.time()
    try:
        data = run_codesys(job, settings, out_dir, args.timeout)
    except cli.CdsError as exc:
        print(f"[verify] {exc}", file=sys.stderr)
        return EXIT_ENV
    except subprocess.TimeoutExpired:
        print(f"[verify] таймаут CODESYS ({args.timeout:.0f} с)", file=sys.stderr)
        return EXIT_TIMEOUT
    except RuntimeError as exc:
        print(f"[verify] {exc}", file=sys.stderr)
        return EXIT_ENV
    reports = evaluate(cases, data)
    for line in report_lines(reports, markdown=False):
        print(line)
    (out_dir / "verify.json").write_text(
        json.dumps(to_json(reports, cases), ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n"
    )
    (out_dir / "verify.md").write_text("\n".join(report_lines(reports, markdown=True)) + "\n", encoding="utf-8")
    # файлы без текстов объявлений (--structural) — для сведения: показывают, что теряет структурная часть TC6
    ok = all(r.ok for r in reports if not r.informational)
    print(f"[verify] {'OK' if ok else 'ОШИБКА'}: прогонов {len(reports)}, {time.time() - started:.0f} с")
    return EXIT_OK if ok else EXIT_FAILED


if __name__ == "__main__":
    sys.exit(main())
