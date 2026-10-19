#!/usr/bin/env python3
"""Маркеры проверки переноса: каждое место с непроверенной в Astra.IDE конструкцией помечено.

Где поведение Astra.IDE не подтверждено документацией вендора (docs/differences.md, «проверить
вручную»), код остаётся в форме CODESYS, а над строкой стоит маркер

    // PORT: [категория] проверить в Astra.IDE — <что> (<пункт чек-листа>)

Инструмент находит такие конструкции по правилам (RULES), сверяет их с маркерами и:
- по умолчанию печатает отчёт: места без маркера, лишние маркеры, сводку по пунктам чек-листа;
- с --fix расставляет недостающие маркеры и убирает лишние;
- с --resolve ПУНКТ отмечает пункт проверенным (маркеры пункта больше не нужны и удаляются);
- с --fail ПУНКТ отмечает пункт проваленным (конструкция в Astra.IDE не работает: каждое её
  место — ошибка, пока код не переписан).

Решения по пунктам хранятся в targets/astra/port_checks.json (verified, failed) — их видно в git.
Маркеры без правила (поставлены вручную, например в адаптерах) допустимы и попадают в сводку.

Коды выхода: 0 — успех; 1 — с --strict есть места без маркера, лишние маркеры или места
проваленных пунктов; 2 — неверные аргументы, нет каталога или ошибка файла решений.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from collections.abc import Iterable, Sequence
from dataclasses import dataclass, field

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(TOOLS_DIR)
sys.path.insert(0, os.path.join(TOOLS_DIR, "codesys"))

import stlayout as L  # noqa: E402

DEFAULT_CONFIG = os.path.join(REPO_ROOT, "targets", "astra", "port_checks.json")
DEFAULT_TREES = ("targets/astra/src", "targets/astra/lib/src")
CHECK_PHRASE = "проверить в Astra.IDE"
DASH = "—"

# Пункт чек-листа: A1…K4, но F1–F4 — визуализация, а F01…F93 — факты (с ведущим нулём или двузначные)
ITEM_RE = re.compile(r"\b(?:[A-EG-K]\d{1,2}|F[1-9])\b")
MARKER_RE = re.compile(r"^//\s*PORT\s*:\s*(?:\[(?P<tag>[^\]]*)\])?\s*(?P<reason>.*?)\s*$")


class UsageError(Exception):
    """Неверные аргументы, нет каталога или файл решений испорчен (код выхода 2)."""


@dataclass(frozen=True)
class Rule:
    """Конструкция, поведение которой в Astra.IDE не подтверждено."""

    id: str
    tag: str
    item: str
    what: str
    pattern: re.Pattern[str]
    suffixes: tuple[str, ...] = ()
    path_part: str = ""
    file_requires: re.Pattern[str] | None = None

    def applies_to(self, rel_path: str, text: str) -> bool:
        name = rel_path.rsplit("/", 1)[-1].lower()
        if self.suffixes and not name.endswith(self.suffixes):
            return False
        if self.path_part and self.path_part not in "/" + rel_path:
            return False
        return self.file_requires is None or self.file_requires.search(text) is not None

    def describe(self, match: re.Match[str]) -> str:
        return self.what.format(*match.groups()) if match.groups() else self.what


def _re(pattern: str, flags: int = 0) -> re.Pattern[str]:
    return re.compile(pattern, re.IGNORECASE | flags)


_INT_TYPES = r"(?:SINT|USINT|INT|UINT|DINT|UDINT|LINT|ULINT|BYTE|WORD|DWORD|LWORD)"

# Пункты и факты — docs/migration_checklist.md (раздел 9) и docs/differences.md (приложение).
RULES: tuple[Rule, ...] = (
    Rule(
        "oop.extends_fb",
        "oop",
        "C1",
        "наследование ФБ (EXTENDS)",
        _re(r"^\s*FUNCTION_BLOCK\b.*\bEXTENDS\b"),
        (L.SUFFIX_DECL,),
    ),
    Rule("oop.super", "oop", "C1", "вызов базовой реализации SUPER^", _re(r"\bSUPER\s*\^")),
    Rule("oop.this", "oop", "C2", "THIS^", _re(r"\bTHIS\s*\^")),
    Rule("oop.abstract", "oop", "C2", "ABSTRACT", _re(r"^\s*(?:FUNCTION_BLOCK|METHOD|PROPERTY)\b.*\bABSTRACT\b")),
    Rule(
        "oop.access",
        "oop",
        "C3",
        "спецификатор доступа {0}",
        _re(r"^\s*(?:METHOD|PROPERTY)\b[^:]*?\b(PRIVATE|PROTECTED|INTERNAL)\b"),
    ),
    Rule(
        "oop.property_fb",
        "oop",
        "C3",
        "свойство пользовательского ФБ (PROPERTY)",
        _re(r"^\s*PROPERTY\b"),
        (L.SUFFIX_PROP_DECL,),
        "/POUs/",
    ),
    Rule(
        "oop.property_itf",
        "oop",
        "C3",
        "свойство интерфейса (PROPERTY)",
        _re(r"^\s*PROPERTY\b"),
        (L.SUFFIX_PROP_DECL,),
        "/Interfaces/",
    ),
    Rule(
        "oop.interface_extends",
        "oop",
        "C4",
        "наследование интерфейсов (EXTENDS)",
        _re(r"^\s*INTERFACE\b.*\bEXTENDS\b"),
        (L.SUFFIX_ITF,),
    ),
    Rule(
        "pragma.strict",
        "pragma",
        "C5",
        "{attribute 'strict'} у перечисления",
        _re(r"\{\s*attribute\s+'strict'\s*\}"),
    ),
    Rule(
        "types.enum_base",
        "types",
        "C7",
        "перечисление с базовым типом {0}",
        _re(r"^\s*\)\s*(" + _INT_TYPES + r")\s*;"),
        (L.SUFFIX_DUT,),
    ),
    Rule(
        "time.ltime_now",
        "time",
        "C11",
        "оператор LTIME(), монотонность",
        _re(r"\bLTIME\s*\(\s*\)"),
    ),
    Rule(
        "types.ltime",
        "types",
        "C11",
        "литералы и преобразования LTIME",
        _re(r"\b(?:LTIME|LT)#|\b\w+_TO_LTIME\b|\bLTIME_TO_\w+"),
    ),
    Rule("types.inout_const", "types", "C13", "VAR_IN_OUT CONSTANT", _re(r"^\s*VAR_IN_OUT\s+CONSTANT\b")),
    Rule("lib.caa_file", "lib", "C10", "CAA File (FILE.*)", _re(r"\bFILE\s*\.\s*[A-Za-z_]")),
    Rule(
        "time.rtc",
        "time",
        "C15",
        "SysTimeRtcHighResGet: UTC в мс, код ERR_OK",
        _re(r"\bSysTimeRtcHighResGet\b"),
    ),
    Rule(
        "lib.mixed_gvl",
        "other",
        "B3",
        "VAR_GLOBAL и VAR_GLOBAL CONSTANT в одном списке [F47]",
        _re(r"^\s*VAR_GLOBAL\s*(?:$|//|\(\*)"),
        (L.SUFFIX_GVL,),
        file_requires=_re(r"^\s*VAR_GLOBAL\s+CONSTANT\b", re.MULTILINE),
    ),
    Rule(
        "retain.pvl",
        "retain",
        "D1",
        "объект Persistent Variables: импорт, объём хранилища [F40]",
        _re(r"^\s*VAR_GLOBAL\s+PERSISTENT\b"),
        (L.SUFFIX_PVL,),
    ),
)
RULE_BY_ID = {rule.id: rule for rule in RULES}


# ---------------------------------------------------------------------------
# Маркеры и места
# ---------------------------------------------------------------------------


@dataclass
class CheckMarker:
    """Маркер проверки в файле: строка (с 1), метка, причина, пункты чек-листа."""

    path: str
    line: int
    tag: str
    reason: str
    items: tuple[str, ...]
    standalone: bool

    @property
    def item(self) -> str:
        return self.items[0] if self.items else ""


@dataclass
class Place:
    """Место конструкции из правила: строка (с 1) и найденные правила с текстом маркера."""

    path: str
    line: int
    indent: str
    rules: list[tuple[Rule, str]] = field(default_factory=list)

    def groups(self) -> dict[tuple[str, str], list[tuple[Rule, str]]]:
        """Правила места по (метка, пункт): одному маркеру — одна пара."""
        out: dict[tuple[str, str], list[tuple[Rule, str]]] = {}
        for rule, what in self.rules:
            out.setdefault((rule.tag, rule.item), []).append((rule, what))
        return out


def marker_text(tag: str, item: str, whats: Sequence[str], indent: str = "") -> str:
    """Строка маркера проверки: одинаковые описания не повторяются."""
    seen: list[str] = []
    for what in whats:
        if what not in seen:
            seen.append(what)
    return f"{indent}// PORT: [{tag}] {CHECK_PHRASE} {DASH} {', '.join(seen)} ({item})"


def parse_check_marker(comment: str) -> tuple[str, str, tuple[str, ...]] | None:
    """`// PORT: [метка] проверить в Astra.IDE — …` → (метка, причина, пункты); иначе None."""
    match = MARKER_RE.match(comment)
    if match is None:
        return None
    reason = match.group("reason")
    if not is_check_reason(reason):
        return None
    tag = (match.group("tag") or "").strip().lower()
    tail = reason
    paren = re.search(r"\(([^()]*)\)\s*$", reason)
    if paren:
        tail = paren.group(1)
    return tag, reason, tuple(ITEM_RE.findall(tail))


def is_check_reason(reason: str) -> bool:
    """Причина маркера начинается с «проверить в Astra.IDE» — это маркер проверки, а не правки."""
    return reason.lower().startswith(CHECK_PHRASE.lower())


def _code_lines(text: str) -> tuple[list[str], dict[int, list[tuple[str, int]]]]:
    """Строки кода без комментариев и строковых литералов (прагмы остаются) и комментарии `//` по строкам.

    Комментарии: номер строки → [(текст, столбец)].
    """
    out: list[str] = []
    comments: dict[int, list[tuple[str, int]]] = {}
    for tok in L.tokenize(text):
        if tok.kind == L.TK_COMMENT:
            if tok.text.startswith("//"):
                comments.setdefault(tok.line, []).append((tok.text, tok.col))
            out.append(re.sub(r"[^\n]", " ", tok.text))
        elif tok.kind in (L.TK_STRING, L.TK_WSTRING):
            out.append(re.sub(r"[^\n]", " ", tok.text))
        else:
            out.append(tok.text)
    lines = "".join(out).split("\n")
    return lines, comments


@dataclass
class FileScan:
    """Разбор одного файла: места правил и маркеры проверки."""

    path: str
    rel: str
    text: str
    places: list[Place]
    markers: list[CheckMarker]
    attached: dict[int, list[CheckMarker]]


def scan_file(path: str, rel: str, text: str, rules: Sequence[Rule] = RULES) -> FileScan:
    """Места правил и маркеры проверки файла. Маркер относится к строке кода, если стоит на ней
    (комментарий в конце строки) или в сплошном блоке строк-комментариев `//` прямо над ней."""
    code, comments = _code_lines(text)
    raw = text.split("\n")
    markers: list[CheckMarker] = []
    for line_no, items in comments.items():
        for comment, col in items:
            parsed = parse_check_marker(comment)
            if parsed is None:
                continue
            tag, reason, marker_items = parsed
            standalone = raw[line_no - 1][: col - 1].strip() == ""
            markers.append(CheckMarker(rel, line_no, tag, reason, marker_items, standalone))
    by_line: dict[int, list[CheckMarker]] = {}
    for marker in markers:
        by_line.setdefault(marker.line, []).append(marker)
    attached: dict[int, list[CheckMarker]] = {}
    places: list[Place] = []
    active = [rule for rule in rules if rule.applies_to(rel, text)]
    for index, line in enumerate(code):
        line_no = index + 1
        if not line.strip():
            continue
        found: list[tuple[Rule, str]] = []
        for rule in active:
            match = rule.pattern.search(line)
            if match:
                found.append((rule, rule.describe(match)))
        mine = [m for m in by_line.get(line_no, []) if not m.standalone]
        k = index - 1
        while k >= 0 and not code[k].strip() and raw[k].strip().startswith("//"):
            mine.extend(by_line.get(k + 1, []))
            k -= 1
        if mine:
            attached[line_no] = mine
        if found:
            indent = raw[index][: len(raw[index]) - len(raw[index].lstrip())]
            places.append(Place(rel, line_no, indent, found))
    return FileScan(path, rel, text, places, markers, attached)


# ---------------------------------------------------------------------------
# Решения по пунктам
# ---------------------------------------------------------------------------


@dataclass
class Decisions:
    """Решения по пунктам чек-листа: проверено (маркеры не нужны) и провалено (конструкция запрещена)."""

    path: str
    trees: list[str]
    verified: dict[str, str]
    failed: dict[str, str]
    doc: list[str]

    def state(self, item: str) -> str:
        if item in self.failed:
            return "failed"
        if item in self.verified:
            return "verified"
        return "open"


DECISIONS_DOC = [
    "Решения по пунктам «проверить вручную» для tools/port_checks.py (docs/migration_checklist.md, раздел 9).",
    "verified — пункт подтверждён в Astra.IDE: маркеры проверки этого пункта не нужны (port_checks --resolve).",
    "failed — конструкция в Astra.IDE не работает: каждое её место — ошибка до переписывания (port_checks --fail).",
    "Значение — дата, версия Astra.IDE и что увидели; ссылка на запись docs/BUILD_ERRORS.md, если есть.",
]


def load_decisions(path: str) -> Decisions:
    if not os.path.exists(path):
        return Decisions(path, list(DEFAULT_TREES), {}, {}, list(DECISIONS_DOC))
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        raise UsageError(f"{path}: {exc}") from exc
    if not isinstance(data, dict):
        raise UsageError(f"{path}: ожидается объект JSON")
    trees = data.get("trees", list(DEFAULT_TREES))
    verified = data.get("verified", {})
    failed = data.get("failed", {})
    doc = data.get("_doc", list(DECISIONS_DOC))
    for key, value in (("trees", trees), ("verified", verified), ("failed", failed)):
        expected = list if key == "trees" else dict
        if not isinstance(value, expected):
            raise UsageError(f"{path}: ключ {key} должен быть {'списком' if expected is list else 'объектом'}")
    both = sorted(set(verified) & set(failed))
    if both:
        raise UsageError(f"{path}: пункты и в verified, и в failed: {', '.join(both)}")
    return Decisions(path, [str(t) for t in trees], dict(verified), dict(failed), [str(d) for d in doc])


def save_decisions(dec: Decisions) -> None:
    data = {
        "_doc": dec.doc,
        "trees": dec.trees,
        "verified": dict(sorted(dec.verified.items(), key=lambda kv: _item_key(kv[0]))),
        "failed": dict(sorted(dec.failed.items(), key=lambda kv: _item_key(kv[0]))),
    }
    L.write_text(dec.path, json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def _item_key(item: str) -> tuple[str, int]:
    match = re.match(r"([A-Z])(\d+)", item)
    return (match.group(1), int(match.group(2))) if match else (item, 0)


# ---------------------------------------------------------------------------
# Проверка дерева
# ---------------------------------------------------------------------------


@dataclass
class Finding:
    """Нарушение: место без маркера, лишний маркер или место проваленного пункта."""

    kind: str
    path: str
    line: int
    tag: str
    item: str
    text: str


KIND_MISSING = "missing"
KIND_EXTRA = "extra"
KIND_FAILED = "failed"
KIND_TITLES = {
    KIND_MISSING: "нет маркера проверки",
    KIND_EXTRA: "лишний маркер (пункт проверен или конструкции нет)",
    KIND_FAILED: "конструкция проваленного пункта",
}


@dataclass
class Report:
    """Итог по деревьям."""

    files: list[FileScan]
    findings: list[Finding]
    decisions: Decisions

    def markers(self) -> list[CheckMarker]:
        return [m for f in self.files for m in f.markers]

    def places(self) -> list[Place]:
        return [p for f in self.files for p in f.places]


def iter_tree(tree: str, base: str) -> Iterable[tuple[str, str, str]]:
    """Файлы *.st дерева: (полный путь, путь от base через /, текст)."""
    root = os.path.join(base, tree) if not os.path.isabs(tree) else tree
    if not os.path.isdir(root):
        raise UsageError(f"нет каталога: {tree}")
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        for name in sorted(filenames):
            if not name.lower().endswith(".st"):
                continue
            full = os.path.join(dirpath, name)
            try:
                rel = os.path.relpath(full, base).replace(os.sep, "/")
            except ValueError:  # другой диск Windows
                rel = full.replace(os.sep, "/")
            yield full, rel, L.read_text(full)


def check_trees(trees: Sequence[str], decisions: Decisions, base: str = REPO_ROOT) -> Report:
    files: list[FileScan] = []
    findings: list[Finding] = []
    for tree in trees:
        for full, rel, text in iter_tree(tree, base):
            scan = scan_file(full, rel, text)
            files.append(scan)
            findings.extend(_file_findings(scan, decisions))
    return Report(files, findings, decisions)


def _rule_generated(marker: CheckMarker) -> bool:
    """Маркер поставлен по правилу: та же пара (метка, пункт) и описание правила в причине.

    Маркеры с другим текстом — ручные (адаптеры, особые места) и проверяются только по пунктам.
    """
    for rule in RULES:
        if rule.tag == marker.tag and rule.item in marker.items and rule.what.split("{")[0].strip() in marker.reason:
            return True
    return False


def _file_findings(scan: FileScan, decisions: Decisions) -> list[Finding]:
    """Нарушения файла.

    - место открытого пункта без маркера своей пары (метка, пункт) — «нет маркера»;
    - место проваленного пункта — «конструкция проваленного пункта» (маркер не спасает);
    - маркер, все пункты которого проверены, — «лишний»;
    - маркер пары из правил, у которого рядом нет конструкции этой пары, — «лишний» (код поменяли,
      маркер остался). Маркеры, поставленные вручную вне правил, не проверяются.
    """
    out: list[Finding] = []
    covered: set[int] = set()  # id маркеров, которые стоят у места своей пары
    for place in scan.places:
        attached = scan.attached.get(place.line, [])
        for (tag, item), rules in place.groups().items():
            whats = ", ".join(what for _, what in rules)
            mine = [m for m in attached if m.tag == tag and item in m.items]
            covered.update(id(m) for m in mine)
            state = decisions.state(item)
            if state == "failed":
                out.append(Finding(KIND_FAILED, scan.rel, place.line, tag, item, whats))
            elif state == "open" and not mine:
                out.append(Finding(KIND_MISSING, scan.rel, place.line, tag, item, whats))
    for marker in scan.markers:
        verified = [i for i in marker.items if decisions.state(i) == "verified"]
        if marker.items and len(verified) == len(marker.items):
            out.append(Finding(KIND_EXTRA, scan.rel, marker.line, marker.tag, ", ".join(verified), marker.reason))
            continue
        if _rule_generated(marker) and id(marker) not in covered:
            out.append(Finding(KIND_EXTRA, scan.rel, marker.line, marker.tag, marker.item, marker.reason))
    return out


def fix_file(scan: FileScan, decisions: Decisions) -> str | None:
    """Новый текст файла: недостающие маркеры вставлены, лишние убраны. None — без изменений."""
    findings = _file_findings(scan, decisions)
    if not any(f.kind in (KIND_MISSING, KIND_EXTRA) for f in findings):
        return None
    lines = scan.text.split("\n")
    extra_lines = {f.line for f in findings if f.kind == KIND_EXTRA}
    insert: dict[int, list[str]] = {}
    for place in scan.places:
        attached = scan.attached.get(place.line, [])
        for (tag, item), rules in place.groups().items():
            if decisions.state(item) != "open":
                continue
            if any(m.tag == tag and item in m.items for m in attached):
                continue
            text = marker_text(tag, item, [what for _, what in rules], place.indent)
            insert.setdefault(place.line, []).append(text)
    out: list[str] = []
    for number, line in enumerate(lines, 1):
        out.extend(insert.get(number, []))
        if number in extra_lines:
            standalone = [m for m in scan.markers if m.line == number and m.standalone]
            if standalone:
                continue
            line = _strip_trailing_marker(line)
        out.append(line)
    new = "\n".join(out)
    return new if new != scan.text else None


def _strip_trailing_marker(line: str) -> str:
    pos = line.find("// PORT:")
    if pos < 0:
        pos = line.find("//PORT:")
    return line[:pos].rstrip() if pos >= 0 else line


# ---------------------------------------------------------------------------
# Отчёт
# ---------------------------------------------------------------------------


def summary_rows(report: Report) -> list[tuple[str, str, str, int, int, int]]:
    """Сводка по пунктам: (пункт, состояние, метка, мест по правилам, маркеров, нарушений)."""
    rows: dict[tuple[str, str], list[int]] = {}
    for place in report.places():
        for tag, item in place.groups():
            rows.setdefault((item, tag), [0, 0, 0])[0] += 1
    for marker in report.markers():
        for item in marker.items or ("—",):
            rows.setdefault((item, marker.tag), [0, 0, 0])[1] += 1
    for finding in report.findings:
        for item in finding.item.split(", "):
            rows.setdefault((item, finding.tag), [0, 0, 0])[2] += 1
    state_titles = {"open": "открыт", "verified": "проверен", "failed": "провален"}
    out = []
    for (item, tag), (places, markers, bad) in sorted(rows.items(), key=lambda kv: (_item_key(kv[0][0]), kv[0][1])):
        state = state_titles[report.decisions.state(item)] if item != "—" else "—"
        out.append((item, state, tag, places, markers, bad))
    return out


def render_text(report: Report) -> str:
    lines = []
    for finding in report.findings:
        lines.append(
            f"{finding.path}:{finding.line}: {KIND_TITLES[finding.kind]}: [{finding.tag}] {finding.item} {finding.text}"
        )
    if lines:
        lines.append("")
    lines.append("Пункт | состояние | метка | мест по правилам | маркеров | нарушений")
    for item, state, tag, places, markers, bad in summary_rows(report):
        lines.append(f"{item} | {state} | {tag} | {places} | {markers} | {bad}")
    return "\n".join(lines)


def summary(report: Report) -> str:
    counts = {kind: sum(1 for f in report.findings if f.kind == kind) for kind in KIND_TITLES}
    return (
        f"port_checks: файлов {len(report.files)}, мест по правилам {len(report.places())}, "
        f"маркеров проверки {len(report.markers())}; без маркера {counts[KIND_MISSING]}, "
        f"лишних {counts[KIND_EXTRA]}, проваленных пунктов {counts[KIND_FAILED]}"
    )


# ---------------------------------------------------------------------------
# Командная строка
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="port_checks.py",
        description="Маркеры // PORT: … проверить в Astra.IDE у конструкций, не подтверждённых документацией.",
    )
    parser.add_argument(
        "--tree",
        action="append",
        metavar="КАТАЛОГ",
        help="каталог раскладки (можно повторять); по умолчанию — trees из файла решений",
    )
    parser.add_argument("--config", default=DEFAULT_CONFIG, help="файл решений (targets/astra/port_checks.json)")
    parser.add_argument("--fix", action="store_true", help="расставить недостающие маркеры и убрать лишние")
    parser.add_argument("--resolve", metavar="ПУНКТ", help="пункт подтверждён в Astra.IDE: убрать его маркеры")
    parser.add_argument("--fail", metavar="ПУНКТ", help="пункт провален: места конструкции — ошибки")
    parser.add_argument("--note", default="", help="для --resolve и --fail: что и где проверено")
    parser.add_argument("--strict", action="store_true", help="код 1 при любом нарушении")
    parser.add_argument("--list-rules", action="store_true", help="напечатать правила и выйти")
    parser.add_argument("-q", "--quiet", action="store_true", help="только нарушения и итог")
    return parser


def configure_output() -> None:
    """Вывод в UTF-8 и при перенаправлении (Windows по умолчанию — cp1251)."""
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="replace")


def _decide(decisions: Decisions, item: str, note: str, failed: bool) -> None:
    if not ITEM_RE.fullmatch(item):
        raise UsageError(f"пункт чек-листа {item!r}: ожидается A1…K4")
    text = note.strip() or f"{dt.date.today().isoformat()}: без комментария"
    if failed:
        decisions.verified.pop(item, None)
        decisions.failed[item] = text
    else:
        decisions.failed.pop(item, None)
        decisions.verified[item] = text
    save_decisions(decisions)


def main(argv: Sequence[str] | None = None) -> int:
    configure_output()
    parser = build_parser()
    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        return 0 if exc.code in (0, None) else 2
    if args.list_rules:
        for rule in RULES:
            where = ", ".join(rule.suffixes) or "все файлы"
            print(f"{rule.item}\t[{rule.tag}]\t{rule.id}\t{rule.what}\t({where})")
        return 0
    try:
        decisions = load_decisions(os.path.abspath(args.config))
        if args.resolve and args.fail:
            raise UsageError("--resolve и --fail — по одному пункту за запуск")
        if args.resolve:
            _decide(decisions, args.resolve, args.note, failed=False)
        if args.fail:
            _decide(decisions, args.fail, args.note, failed=True)
        trees = args.tree or decisions.trees
        report = check_trees(trees, decisions)
        if args.fix or args.resolve:
            changed = 0
            for scan in report.files:
                new = fix_file(scan, decisions)
                if new is not None:
                    L.write_text(scan.path, new)
                    changed += 1
            report = check_trees(trees, decisions)
            if not args.quiet:
                print(f"port_checks: изменено файлов {changed}")
    except UsageError as exc:
        print(f"port_checks: {exc}", file=sys.stderr)
        return 2
    if args.quiet:
        for finding in report.findings:
            print(
                f"{finding.path}:{finding.line}: {KIND_TITLES[finding.kind]}: [{finding.tag}] {finding.item}",
                file=sys.stderr,
            )
    else:
        print(render_text(report))
    print(summary(report))
    if args.strict and report.findings:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
