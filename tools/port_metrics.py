#!/usr/bin/env python3
"""Метрики переноса: сравнение исходной раскладки ST с адаптированной.

Оригинал — раскладки `src/` флагмана и библиотеки (CODESYS 3.5.17.30), адаптированный код —
`targets/astra/src/` (Astra.IDE) в той же раскладке (docs/LAYOUT.md). Каждая правка в
адаптированном коде помечена комментарием `// PORT: [категория] причина`.

Что считается (подробно — раздел «Методика» отчёта, функция methodology_md):
- по файлам, объектам, источникам и итого: строки оригинала без изменений, изменённые,
  переписанные (файл, отличающийся больше чем на порог, по умолчанию 50 %), удалённые или
  не перенесённые, плюс добавленные строки;
- маркеры PORT по категориям причин;
- правки без маркера и маркеры без правки (проверка дисциплины пометок).

Результат: docs/port_metrics.md и docs/port_metrics.json.

Коды выхода: 0 — успех; 1 — ошибки раскладки или (с --strict) правки без маркера, неизвестные
категории, маркеры без причины; 2 — неверные аргументы или нет каталога.
"""

from __future__ import annotations

import argparse
import difflib
import fnmatch
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

SCHEMA_VERSION = 1
DEFAULT_THRESHOLD = 0.5
# Перенос этого репозитория: снимки оригинала (upstream/, коммиты — upstream/SOURCES.json) и адаптированный
# код (targets/astra/). Одинаковые метки у оригинала и адаптированного дерева — объекты сравниваются только
# внутри пары (у библиотеки и флагмана есть одноимённые объекты, например GVL_Const).
DEFAULT_ORIGS = (
    "kns-pump-station=" + os.path.join(REPO_ROOT, "upstream", "kns-pump-station", "src"),
    "plc-process-lib=" + os.path.join(REPO_ROOT, "upstream", "plc-process-lib", "src"),
)
DEFAULT_ADAPTED = (
    "kns-pump-station=" + os.path.join(REPO_ROOT, "targets", "astra", "src"),
    "plc-process-lib=" + os.path.join(REPO_ROOT, "targets", "astra", "lib", "src"),
)
# PRG_Main библиотеки — программа её рабочей сборки, в библиотеку не входит (config.json: library.exclude)
DEFAULT_EXCLUDE = ("plc-process-lib:PRG_Main",)
DEFAULT_MD = os.path.join(REPO_ROOT, "docs", "port_metrics.md")
DEFAULT_JSON = os.path.join(REPO_ROOT, "docs", "port_metrics.json")
NEW_LABEL = "новые объекты"

STATUS_UNCHANGED = "unchanged"
STATUS_CHANGED = "changed"
STATUS_REWRITTEN = "rewritten"
STATUS_NEW = "new"
STATUS_REMOVED = "removed"
STATUSES = (STATUS_UNCHANGED, STATUS_CHANGED, STATUS_REWRITTEN, STATUS_NEW, STATUS_REMOVED)
STATUS_TITLES = {
    STATUS_UNCHANGED: "без изменений",
    STATUS_CHANGED: "изменён",
    STATUS_REWRITTEN: "переписан",
    STATUS_NEW: "новый",
    STATUS_REMOVED: "не перенесён",
}

HUNK_REPLACE = "replace"
HUNK_INSERT = "insert"
HUNK_DELETE = "delete"
HUNK_FILE = "file"
HUNK_TITLES = {
    HUNK_REPLACE: "изменение",
    HUNK_INSERT: "вставка",
    HUNK_DELETE: "удаление",
    HUNK_FILE: "файл без маркера",
}

# Главные файлы объектов: роль файла в паре «оригинал — адаптированный» не зависит от имени объекта,
# поэтому переименованный объект (--map) сравнивается по тем же ролям.
_MAIN_SUFFIXES = (
    L.SUFFIX_DUT,
    L.SUFFIX_GVL,
    L.SUFFIX_PVL,
    L.SUFFIX_ITF,
    L.SUFFIX_DECL,
    L.SUFFIX_IMPL,
)

_MARKER_RE = re.compile(r"^//\s*PORT\s*:\s*(?:\[(?P<tag>[^\]]*)\])?\s*(?P<reason>.*?)\s*$")
# Маркер проверки: код оставлен в форме CODESYS, поведение Astra.IDE не подтверждено (tools/port_checks.py)
CHECK_PHRASE = "проверить в Astra.IDE"
# Пункт чек-листа A1…K4; F1–F4 — визуализация, а F01…F93 — факты (с ведущим нулём или двузначные)
_ITEM_RE = re.compile(r"\b(?:[A-EG-K]\d{1,2}|F[1-9])\b")


@dataclass(frozen=True)
class Category:
    """Категория причины правки: метка в маркере, смысл и ключевые слова для маркера без метки."""

    tag: str
    title: str
    keywords: tuple[str, ...] = ()

    def matches(self, reason: str) -> bool:
        return any(re.search(word, reason, re.IGNORECASE) for word in self.keywords)


# Порядок важен: маркер без метки получает первую категорию, ключевое слово которой есть в причине.
CATEGORIES: tuple[Category, ...] = (
    Category(
        "build",
        "исправление по ошибке компиляции Astra.IDE (docs/BUILD_ERRORS.md)",
        (r"BUILD_ERRORS", r"ошибк\w* компил", r"\bC\d{4}\b"),
    ),
    Category(
        "oop",
        "ООП: наследование ФБ и интерфейсов, SUPER^/THIS^, ABSTRACT, спецификаторы доступа, свойства",
        (r"\bEXTENDS\b", r"SUPER\^", r"THIS\^", r"\bABSTRACT\b", r"\bPROTECTED\b", r"\bPRIVATE\b", r"наслед"),
    ),
    Category("retain", "RETAIN и PERSISTENT", (r"\bRETAIN\b", r"PERSISTENT", r"энергонезав")),
    Category(
        "pragma",
        "прагмы и атрибуты",
        (r"\{attribute", r"\battribute\b", r"прагм", r"атрибут", r"qualified_only", r"pack_mode"),
    ),
    Category("opcua", "OPC UA и символьная конфигурация", (r"OPC\s?UA", r"символьн")),
    Category("hmi", "визуализация (TargetVisu, WebVisu)", (r"визуализ", r"WebVisu", r"TargetVisu", r"\bHMI\b")),
    Category(
        "comm",
        "связь: Modbus RTU/TCP, последовательные порты",
        (r"Modbus", r"RS-?485", r"RS-?232", r"Serial", r"последовательн\w* порт"),
    ),
    Category("io", "ввод-вывод: модули REGUL, слой GVL_IO", (r"ввод-вывод", r"\bGVL_IO\b", r"RegulBus", r"\bI/O\b")),
    Category("time", "источник времени", (r"SysTime", r"PsTime", r"источник\w* времени", r"\bLTIME\(\)")),
    Category("test", "тесты: coUnit, PsUnittest", (r"coUnit", r"CfUnit", r"PsUnittest")),
    Category("task", "задачи, приоритеты, сторожевой таймер", (r"задач", r"приоритет", r"сторожев")),
    Category(
        "lib",
        "библиотеки и пространства имён",
        (r"библиотек", r"\bCAA\b", r"\bSysFile", r"пространств\w* имён", r"\bnamespace\b"),
    ),
    Category(
        "types",
        "типы данных и конструкции языка",
        (r"\bLTIME\b", r"\bUNION\b", r"VAR_IN_OUT", r"VAR_STAT", r"__NEW", r"перечислени", r"\bSTRUCT\b"),
    ),
    Category("other", "прочее"),
)
CATEGORY_BY_TAG = {cat.tag: cat for cat in CATEGORIES}
OTHER_TAG = "other"


class UsageError(Exception):
    """Неверные аргументы или отсутствующий каталог (код выхода 2)."""


# ---------------------------------------------------------------------------
# Данные
# ---------------------------------------------------------------------------


@dataclass
class Marker:
    """Маркер `// PORT:` в адаптированном файле."""

    path: str
    line: int
    tag: str
    reason: str
    explicit: bool
    raw_tag: str | None = None
    used: bool = False
    check: bool = False
    items: tuple[str, ...] = ()

    @property
    def unknown_tag(self) -> bool:
        return self.raw_tag is not None and self.raw_tag.strip().lower() not in CATEGORY_BY_TAG

    def to_json(self) -> dict[str, object]:
        return {
            "path": self.path,
            "line": self.line,
            "category": self.tag,
            "explicit": self.explicit,
            "raw_tag": self.raw_tag,
            "reason": self.reason,
            "used": self.used,
            "check": self.check,
            "items": list(self.items),
        }


@dataclass
class Hunk:
    """Участок правки в паре файлов: индексы — по значимым строкам, line — строка адаптированного файла."""

    kind: str
    orig_start: int
    orig_end: int
    adapted_start: int
    adapted_end: int
    line: int
    text: str
    marked: bool = False
    category: str | None = None

    def to_json(self, path: str) -> dict[str, object]:
        return {"path": path, "line": self.line, "kind": self.kind, "text": self.text}


@dataclass
class LineCounts:
    """Строки оригинала и адаптированной версии, разложение строк оригинала и добавленные строки."""

    orig: int = 0
    adapted: int = 0
    unchanged: int = 0
    changed: int = 0
    rewritten: int = 0
    removed: int = 0
    added: int = 0
    # Сумма max(строк оригинала, строк адаптированного) по файлам: знаменатель различия
    span: int = 0

    def add(self, other: LineCounts) -> None:
        self.orig += other.orig
        self.adapted += other.adapted
        self.unchanged += other.unchanged
        self.changed += other.changed
        self.rewritten += other.rewritten
        self.removed += other.removed
        self.added += other.added
        self.span += other.span

    @property
    def difference(self) -> float:
        """Различие: 1 - (строк без изменений) / max(строк оригинала, строк адаптированного)."""
        if self.span == 0:
            return 0.0
        return 1.0 - self.unchanged / self.span

    def to_json(self) -> dict[str, object]:
        return {
            "orig_lines": self.orig,
            "adapted_lines": self.adapted,
            "unchanged": self.unchanged,
            "changed": self.changed,
            "rewritten": self.rewritten,
            "removed": self.removed,
            "added": self.added,
            "difference": round(self.difference, 4),
        }


@dataclass
class TextLines:
    """Значимые строки текста: нормализованные строки, их номера в файле и маркеры PORT."""

    lines: list[str]
    raw_numbers: list[int]
    raw_count: int
    markers: list[tuple[int, str | None, str]]


@dataclass
class FileResult:
    """Сравнение одного файла раскладки."""

    role: str
    status: str
    counts: LineCounts
    display: str = ""
    orig_path: str | None = None
    adapted_path: str | None = None
    markers: list[Marker] = field(default_factory=list)
    hunks: list[Hunk] = field(default_factory=list)
    # Категория нового или переписанного файла — по первому маркеру правки
    category: str | None = None

    @property
    def change_markers(self) -> list[Marker]:
        return [m for m in self.markers if not m.check]

    @property
    def unmarked(self) -> list[Hunk]:
        return [h for h in self.hunks if not h.marked]

    def to_json(self) -> dict[str, object]:
        data: dict[str, object] = {
            "file": self.display,
            "role": self.role,
            "status": self.status,
            "orig_path": self.orig_path,
            "adapted_path": self.adapted_path,
            "markers": len(self.markers),
            "unmarked_hunks": len(self.unmarked),
        }
        data.update(self.counts.to_json())
        return data


@dataclass
class ObjectResult:
    """Сравнение объекта (DUT, GVL, интерфейс, POU) по всем его файлам."""

    name: str
    label: str
    kind: str
    status: str
    counts: LineCounts
    orig_name: str | None = None
    files: list[FileResult] = field(default_factory=list)
    layout_kind: str = L.KIND_POU

    @property
    def markers(self) -> int:
        return sum(len(f.markers) for f in self.files)

    def to_json(self) -> dict[str, object]:
        data: dict[str, object] = {
            "name": self.name,
            "orig_name": self.orig_name,
            "source": self.label,
            "kind": self.kind,
            "status": self.status,
            "markers": self.markers,
        }
        data.update(self.counts.to_json())
        return data


@dataclass
class Source:
    """Каталог раскладки: метка, абсолютный путь и путь для отчёта."""

    label: str
    path: str
    display: str


@dataclass
class Report:
    """Итог сравнения."""

    threshold: float
    with_comments: bool
    origs: list[Source]
    adapted: list[Source]
    objects: list[ObjectResult]
    warnings: list[str] = field(default_factory=list)
    command: str = ""

    @property
    def files(self) -> list[FileResult]:
        return [f for obj in self.objects for f in obj.files]

    @property
    def markers(self) -> list[Marker]:
        return [m for f in self.files for m in f.markers]

    @property
    def unmarked(self) -> list[tuple[FileResult, Hunk]]:
        return [(f, h) for f in self.files for h in f.unmarked]

    @property
    def change_markers(self) -> list[Marker]:
        return [m for m in self.markers if not m.check]

    @property
    def check_markers(self) -> list[Marker]:
        return [m for m in self.markers if m.check]

    @property
    def stale_markers(self) -> list[Marker]:
        """Маркеры правки, не относящиеся ни к одной правке (маркеры проверки правкой не являются)."""
        return [m for m in self.change_markers if not m.used]

    def totals(self) -> LineCounts:
        total = LineCounts()
        for obj in self.objects:
            total.add(obj.counts)
        return total

    def by_label(self) -> list[tuple[str, LineCounts, int]]:
        """Итоги по источникам в порядке --orig, затем новые объекты: (метка, строки, объектов)."""
        order = [s.label for s in self.origs]
        order += [NEW_LABEL] if NEW_LABEL not in order else []
        sums: dict[str, LineCounts] = {label: LineCounts() for label in order}
        count: dict[str, int] = dict.fromkeys(order, 0)
        for obj in self.objects:
            sums[obj.label].add(obj.counts)
            count[obj.label] += 1
        return [(label, sums[label], count[label]) for label in order if count[label]]

    def strict_problems(self) -> list[str]:
        """Нарушения дисциплины пометок, из-за которых --strict даёт код выхода 1."""
        problems = [f"{f.display}:{h.line}: правка без маркера PORT ({HUNK_TITLES[h.kind]})" for f, h in self.unmarked]
        for marker in self.markers:
            if marker.unknown_tag:
                problems.append(f"{marker.path}:{marker.line}: неизвестная категория [{marker.raw_tag}]")
            if not marker.reason:
                problems.append(f"{marker.path}:{marker.line}: маркер PORT без причины")
        return problems


# ---------------------------------------------------------------------------
# Строки и маркеры
# ---------------------------------------------------------------------------


def parse_marker(comment: str) -> tuple[str | None, str] | None:
    """Комментарий `// PORT: [метка] причина` → (метка или None, причина); иначе None."""
    match = _MARKER_RE.match(comment)
    if match is None:
        return None
    return match.group("tag"), match.group("reason")


def classify(raw_tag: str | None, reason: str) -> tuple[str, bool]:
    """Категория маркера и признак явной метки. Неизвестная метка — категория other."""
    if raw_tag is not None:
        tag = raw_tag.strip().lower()
        return (tag if tag in CATEGORY_BY_TAG else OTHER_TAG), True
    for cat in CATEGORIES:
        if cat.matches(reason):
            return cat.tag, False
    return OTHER_TAG, False


def _blank(text: str) -> str:
    return re.sub(r"[^\n]", " ", text)


def significant_lines(text: str, with_comments: bool = False) -> TextLines:
    """Значимые строки текста ST.

    Маркеры PORT вырезаются всегда (пометка правки — не код); без with_comments вырезаются все
    комментарии. Прагмы остаются: атрибуты меняют поведение компилятора. Строка нормализуется
    схлопыванием пробелов; пустая после этого строка не значима.
    """
    out: list[str] = []
    markers: list[tuple[int, str | None, str]] = []
    for tok in L.tokenize(text):
        if tok.kind == L.TK_COMMENT:
            parsed = parse_marker(tok.text) if tok.text.startswith("//") else None
            if parsed is not None:
                markers.append((tok.line, parsed[0], parsed[1]))
                out.append(_blank(tok.text))
                continue
            if not with_comments:
                out.append(_blank(tok.text))
                continue
        out.append(tok.text)
    raw = "".join(out).split("\n")
    if raw and raw[-1] == "":
        raw.pop()
    lines: list[str] = []
    numbers: list[int] = []
    for number, line in enumerate(raw, 1):
        norm = L.squash_ws(line)
        if norm:
            lines.append(norm)
            numbers.append(number)
    return TextLines(lines, numbers, len(raw), markers)


def _hunks(orig: TextLines, adapted: TextLines) -> tuple[LineCounts, list[Hunk]]:
    """Разложение строк по участкам правок difflib (без порога «переписан»)."""
    counts = LineCounts(orig=len(orig.lines), adapted=len(adapted.lines))
    counts.span = max(counts.orig, counts.adapted)
    matcher = difflib.SequenceMatcher(None, orig.lines, adapted.lines, autojunk=False)
    hunks: list[Hunk] = []
    # Между двумя совпадающими блоками get_opcodes даёт ровно одну операцию: участки не сливаются
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        if tag == "equal":
            counts.unchanged += i2 - i1
            continue
        if tag == HUNK_REPLACE:
            counts.changed += i2 - i1
            counts.added += max(0, (j2 - j1) - (i2 - i1))
        elif tag == HUNK_DELETE:
            counts.removed += i2 - i1
        else:
            counts.added += j2 - j1
        if j2 > j1:
            line, text = adapted.raw_numbers[j1], adapted.lines[j1]
        else:
            line, text = (adapted.raw_numbers[j1 - 1] if j1 > 0 else 1), orig.lines[i1]
        hunks.append(Hunk(tag, i1, i2, j1, j2, line, text))
    return counts, hunks


def _window(adapted: TextLines, hunk: Hunk) -> tuple[int, int]:
    """Строки файла (включительно), где маркер относится к участку правки.

    Изменение и вставка: от строки после предыдущей значимой до последней строки участка —
    маркер в строке правки или в комментарии над ней. Удаление: от предыдущей значимой строки
    до следующей включительно.
    """
    k1, k2 = hunk.adapted_start, hunk.adapted_end
    prev = adapted.raw_numbers[k1 - 1] if k1 > 0 else 0
    if k2 > k1:
        return prev + 1, adapted.raw_numbers[k2 - 1]
    nxt = adapted.raw_numbers[k1] if k1 < len(adapted.raw_numbers) else adapted.raw_count
    return max(prev, 1), max(nxt, 1)


def is_check_reason(reason: str) -> bool:
    """Маркер проверки: причина начинается с «проверить в Astra.IDE» — это не правка кода."""
    return reason.lower().startswith(CHECK_PHRASE.lower())


def marker_items(reason: str) -> tuple[str, ...]:
    """Пункты чек-листа из последних скобок причины: «… (C1)», «… (E1, E2)»."""
    paren = re.search(r"\(([^()]*)\)\s*$", reason)
    return tuple(_ITEM_RE.findall(paren.group(1))) if paren else ()


def _make_markers(path: str, parsed: Iterable[tuple[int, str | None, str]]) -> list[Marker]:
    result = []
    for line, raw_tag, reason in parsed:
        tag, explicit = classify(raw_tag, reason)
        check = is_check_reason(reason)
        items = marker_items(reason)
        result.append(Marker(path, line, tag, reason, explicit, raw_tag, check=check, items=items))
    return result


def _first_category(markers: Iterable[Marker]) -> str | None:
    return next((m.tag for m in markers if not m.check), None)


def compare_texts(
    orig: str | None,
    adapted: str | None,
    threshold: float = DEFAULT_THRESHOLD,
    with_comments: bool = False,
    display: str = "",
    role: str = "",
) -> FileResult:
    """Сравнивает версии одного файла (None — файла нет в этой версии)."""
    if adapted is None:
        if orig is None:
            raise ValueError("нужна хотя бы одна версия файла")
        n = len(significant_lines(orig, with_comments).lines)
        return FileResult(role, STATUS_REMOVED, LineCounts(orig=n, removed=n, span=n), display)
    new = significant_lines(adapted, with_comments)
    markers = _make_markers(display, new.markers)
    if orig is None:
        n = len(new.lines)
        for marker in markers:
            marker.used = True
        return FileResult(
            role,
            STATUS_NEW,
            LineCounts(adapted=n, added=n, span=n),
            display,
            markers=markers,
            category=_first_category(markers),
        )
    counts, hunks = _hunks(significant_lines(orig, with_comments), new)
    if not hunks:
        return FileResult(role, STATUS_UNCHANGED, counts, display, markers=markers)
    if counts.orig > 0 and counts.adapted > 0 and counts.difference > threshold:
        rewritten = LineCounts(
            orig=counts.orig,
            adapted=counts.adapted,
            rewritten=counts.orig,
            added=max(0, counts.adapted - counts.orig),
            span=counts.span,
        )
        result = FileResult(
            role, STATUS_REWRITTEN, rewritten, display, markers=markers, category=_first_category(markers)
        )
        for marker in markers:
            marker.used = True
        if not result.change_markers:
            result.hunks = [Hunk(HUNK_FILE, 0, counts.orig, 0, counts.adapted, 1, new.lines[0])]
        return result
    for hunk in hunks:
        first, last = _window(new, hunk)
        for marker in markers:
            # Маркер проверки отмечает место без правки и правку не помечает
            if not marker.check and first <= marker.line <= last:
                hunk.marked = True
                marker.used = True
                if hunk.category is None:
                    hunk.category = marker.tag
    return FileResult(role, STATUS_CHANGED, counts, display, markers=markers, hunks=hunks)


# ---------------------------------------------------------------------------
# Деревья раскладки
# ---------------------------------------------------------------------------


@dataclass
class _Entry:
    """Объект раскладки и его файлы: роль → (путь для отчёта, текст)."""

    obj: L.StObject
    source: Source
    files: dict[str, tuple[str, str]]


def file_role(obj: L.StObject, rel_path: str) -> str:
    """Роль файла в объекте: суффикс главного файла или имя файла члена (в нижнем регистре)."""
    base = rel_path.rsplit("/", 1)[-1]
    for suffix in _MAIN_SUFFIXES:
        if base.lower() == (obj.name + suffix).lower():
            return suffix
    return base.lower()


def _display_path(path: str, base: str) -> str:
    try:
        rel = os.path.relpath(path, base)
    except ValueError:  # другой диск Windows
        rel = path
    return rel.replace(os.sep, "/")


def parse_source(spec: str, base: str) -> Source:
    """`[МЕТКА=]КАТАЛОГ` → Source; метка по умолчанию — имя каталога над раскладкой."""
    label = ""
    path = spec
    head, sep, tail = spec.partition("=")
    if sep and re.fullmatch(r"[\w.\-]+", head):
        label, path = head, tail
    full = os.path.abspath(path)
    if not label:
        label = os.path.basename(os.path.dirname(full)) or os.path.basename(full)
    return Source(label, full, _display_path(full, base))


def load_tree(source: Source, base: str) -> tuple[list[_Entry], list[str]]:
    """Читает раскладку: объекты и ошибки раскладки (LAY...)."""
    path = source.path.rstrip("\\/")
    if not os.path.isdir(path):
        raise UsageError(f"нет каталога раскладки: {source.display}")
    root, sub = os.path.split(path)
    result = L.scan(root, sub)
    errors = [issue.format() for issue in result.errors]
    entries = []
    for obj in result.objects:
        files: dict[str, tuple[str, str]] = {}
        for rel, text in L.object_files(obj):
            full = os.path.join(root, *rel.split("/"))
            files[file_role(obj, rel)] = (_display_path(full, base), text)
        entries.append(_Entry(obj, source, files))
    return entries, errors


def _excluded(entry: _Entry, patterns: Sequence[str]) -> bool:
    names = (entry.obj.name.lower(), f"{entry.source.label}:{entry.obj.name}".lower())
    return any(fnmatch.fnmatchcase(name, pattern.lower()) for pattern in patterns for name in names)


def _index(entries: Iterable[_Entry], what: str, warnings: list[str]) -> dict[str, _Entry]:
    index: dict[str, _Entry] = {}
    for entry in entries:
        key = entry.obj.name.lower()
        if key in index:
            first, name, label = index[key].source.label, entry.obj.name, entry.source.label
            warnings.append(
                f"{what}: объект {name} есть в {first} и в {label}; взят первый (исключить — --exclude {label}:{name})"
            )
            continue
        index[key] = entry
    return index


def _object_status(files: Sequence[FileResult], counts: LineCounts, threshold: float) -> str:
    statuses = {f.status for f in files}
    for status in (STATUS_NEW, STATUS_REMOVED, STATUS_UNCHANGED):
        if statuses <= {status}:
            return status
    if counts.orig > 0 and counts.adapted > 0 and counts.difference > threshold:
        return STATUS_REWRITTEN
    return STATUS_CHANGED


def _compare_entries(
    orig: _Entry | None, adapted: _Entry | None, threshold: float, with_comments: bool
) -> ObjectResult:
    some = adapted or orig
    assert some is not None
    roles: list[str] = []
    for entry in (orig, adapted):
        if entry is not None:
            roles.extend(role for role in entry.files if role not in roles)
    files: list[FileResult] = []
    for role in roles:
        o = orig.files.get(role) if orig else None
        a = adapted.files.get(role) if adapted else None
        shown = a or o
        assert shown is not None
        result = compare_texts(
            o[1] if o else None,
            a[1] if a else None,
            threshold=threshold,
            with_comments=with_comments,
            display=shown[0],
            role=role,
        )
        result.orig_path = o[0] if o else None
        result.adapted_path = a[0] if a else None
        files.append(result)
    counts = LineCounts()
    for result in files:
        counts.add(result.counts)
    if orig is not None and adapted is not None:
        # Новый файл в перенесённом объекте (метод, свойство) требует собственного маркера
        for result in files:
            if result.status == STATUS_NEW and not result.change_markers:
                text = adapted.files[result.role][1].split("\n", 1)[0]
                result.hunks = [Hunk(HUNK_FILE, 0, 0, 0, result.counts.adapted, 1, text)]
    elif adapted is not None and not any(result.change_markers for result in files):
        # Новый объект: достаточно одного маркера в любом его файле (обычно в объявлении)
        files[0].hunks = [Hunk(HUNK_FILE, 0, 0, 0, files[0].counts.adapted, 1, adapted.obj.name)]
    return ObjectResult(
        name=some.obj.name,
        label=orig.source.label if orig is not None else NEW_LABEL,
        kind=some.obj.pou_kind or some.obj.kind,
        status=_object_status(files, counts, threshold),
        counts=counts,
        orig_name=orig.obj.name if orig is not None else None,
        files=files,
        layout_kind=some.obj.kind,
    )


def build_report(
    origs: Sequence[Source],
    adapted: Sequence[Source],
    threshold: float = DEFAULT_THRESHOLD,
    with_comments: bool = False,
    exclude: Sequence[str] = (),
    renames: Sequence[tuple[str, str]] = (),
    base: str = REPO_ROOT,
) -> tuple[Report, list[str]]:
    """Сравнивает раскладки. Возвращает отчёт и ошибки раскладки (с ошибками отчёт неполон).

    Адаптированное дерево с той же меткой, что у оригинала, сравнивается только с ним (пара);
    остальные адаптированные деревья — со всеми оригиналами без пары.
    """
    if not 0.0 <= threshold < 1.0:
        raise UsageError(f"порог должен быть в диапазоне [0, 1): {threshold}")
    warnings: list[str] = []
    errors: list[str] = []
    orig_groups: dict[str | None, list[_Entry]] = {}
    adapted_groups: dict[str | None, list[_Entry]] = {}
    paired = {s.label for s in adapted} & {s.label for s in origs}
    for sources, groups in ((origs, orig_groups), (adapted, adapted_groups)):
        for source in sources:
            entries, errs = load_tree(source, base)
            errors.extend(errs)
            key = source.label if source.label in paired else None
            groups.setdefault(key, []).extend(e for e in entries if not _excluded(e, exclude))
    rename_map: dict[str, str] = {}  # имя в адаптированном коде -> имя в оригинале (нижний регистр)
    all_orig = {e.obj.name.lower() for es in orig_groups.values() for e in es}
    all_adapted = {e.obj.name.lower() for es in adapted_groups.values() for e in es}
    for old, new in renames:
        if old.lower() not in all_orig:
            warnings.append(f"--map {old}={new}: в оригинале нет объекта {old}")
        if new.lower() not in all_adapted:
            warnings.append(f"--map {old}={new}: в адаптированном коде нет объекта {new}")
        rename_map[new.lower()] = old.lower()
    renamed = set(rename_map.values())
    objects: list[ObjectResult] = []
    for key in sorted(set(orig_groups) | set(adapted_groups), key=lambda k: (k is not None, k or "")):
        suffix = f" ({key})" if key is not None else ""
        orig_index = _index(orig_groups.get(key, []), "оригинал" + suffix, warnings)
        adapted_index = _index(adapted_groups.get(key, []), "адаптированный код" + suffix, warnings)
        matched: set[str] = set()
        for name, entry in adapted_index.items():
            if name in rename_map:
                orig_key: str | None = rename_map[name]
            else:
                # Имя оригинала, переименованного в другой объект, занято: одноимённый объект — новый
                orig_key = None if name in renamed else name
            orig_entry = orig_index.get(orig_key) if orig_key is not None else None
            if orig_entry is not None and orig_key is not None:
                matched.add(orig_key)
            objects.append(_compare_entries(orig_entry, entry, threshold, with_comments))
        for name, entry in orig_index.items():
            if name not in matched:
                objects.append(_compare_entries(entry, None, threshold, with_comments))

    label_order = {s.label: i for i, s in enumerate(origs)}
    label_order.setdefault(NEW_LABEL, len(label_order))
    category_order = {cat: i for i, cat in enumerate(L.CATEGORIES)}
    kind_category = {
        L.KIND_DUT: L.CAT_DUTS,
        L.KIND_GVL: L.CAT_GVLS,
        L.KIND_PVL: L.CAT_GVLS,
        L.KIND_ITF: L.CAT_ITFS,
        L.KIND_POU: L.CAT_POUS,
    }

    def sort_key(obj: ObjectResult) -> tuple[int, int, str, str]:
        return (
            label_order.get(obj.label, len(label_order)),
            category_order[kind_category[obj.layout_kind]],
            obj.name.lower(),
            obj.name,
        )

    objects.sort(key=sort_key)
    return Report(threshold, with_comments, list(origs), list(adapted), objects, warnings), errors


@dataclass
class CategoryStats:
    """Правки одной категории: маркеры, объекты и файлы с правками, строки."""

    tag: str
    changes: int = 0
    checks: int = 0
    objects: set[str] = field(default_factory=set)
    files: set[str] = field(default_factory=set)
    orig_lines: int = 0
    added_lines: int = 0

    def to_json(self) -> dict[str, object]:
        return {
            "category": self.tag,
            "change_markers": self.changes,
            "check_markers": self.checks,
            "objects": len(self.objects),
            "files": len(self.files),
            "orig_lines_touched": self.orig_lines,
            "lines_added": self.added_lines,
        }


def category_stats(report: Report) -> list[CategoryStats]:
    """Правки по категориям в порядке CATEGORIES.

    Строки участка правки относятся к категории первого маркера правки в его окне; новый или
    переписанный файл — к первому маркеру правки файла, а без него — к первому маркеру правки
    объекта (новому объекту достаточно одного маркера). Строки оригинала — изменённые, переписанные
    и удалённые; добавленные — строки адаптированного кода в участках правок и новых файлах.
    """
    stats = {cat.tag: CategoryStats(cat.tag) for cat in CATEGORIES}
    for marker in report.markers:
        slot = stats.get(marker.tag, stats[OTHER_TAG])
        if marker.check:
            slot.checks += 1
        else:
            slot.changes += 1
    for obj in report.objects:
        object_category = _first_category(m for f in obj.files for m in f.markers)
        for f in obj.files:
            touched: list[tuple[str, int, int]] = []
            if f.status in (STATUS_NEW, STATUS_REWRITTEN):
                tag = f.category or object_category
                if tag is not None:
                    touched.append((tag, f.counts.rewritten, f.counts.adapted))
            elif f.status == STATUS_CHANGED:
                for hunk in f.hunks:
                    if hunk.category is not None:
                        touched.append(
                            (hunk.category, hunk.orig_end - hunk.orig_start, hunk.adapted_end - hunk.adapted_start)
                        )
            for tag, orig_lines, added in touched:
                slot = stats.get(tag, stats[OTHER_TAG])
                slot.objects.add(f"{obj.label}:{obj.name}")
                slot.files.add(f.display)
                slot.orig_lines += orig_lines
                slot.added_lines += added
    return [st for st in stats.values() if st.changes or st.checks or st.files]


def _item_key(item: str) -> tuple[str, int]:
    match = re.match(r"([A-Z])(\d+)", item)
    return (match.group(1), int(match.group(2))) if match else ("~", 0)


def check_items(report: Report) -> list[tuple[str, int, list[str]]]:
    """Маркеры проверки по пунктам чек-листа: (пункт, маркеров, категории)."""
    rows: dict[str, tuple[int, list[str]]] = {}
    for marker in report.check_markers:
        for item in marker.items or ("—",):
            count, tags = rows.get(item, (0, []))
            if marker.tag not in tags:
                tags = [*tags, marker.tag]
            rows[item] = (count + 1, tags)
    return [(item, rows[item][0], rows[item][1]) for item in sorted(rows, key=_item_key)]


# ---------------------------------------------------------------------------
# Отчёт
# ---------------------------------------------------------------------------


def _pct(part: int, whole: int) -> str:
    if whole == 0:
        return "—"
    return f"{100.0 * part / whole:.1f} %".replace(".", ",")


def _cell(part: int, whole: int) -> str:
    return f"{part} ({_pct(part, whole)})" if whole else str(part)


def _ratio(value: float) -> str:
    return f"{100.0 * value:.0f} %"


def _md_escape(text: str) -> str:
    return text.replace("|", "\\|").replace("`", "'")


def _snippet(text: str, limit: int = 70) -> str:
    text = text.strip()
    if len(text) > limit:
        text = text[: limit - 1] + "…"
    return f"`{_md_escape(text)}`" if text else ""


def _row(*cells: object) -> str:
    return "| " + " | ".join(str(c) for c in cells) + " |"


def _header(*titles: str) -> list[str]:
    return [_row(*titles), "|" + "---|" * len(titles)]


def methodology_md() -> list[str]:
    """Раздел «Методика»: постоянный текст (тест проверяет, что docs/port_metrics.md его содержит)."""
    lines = [
        "## Методика",
        "",
        "Отчёт строит `tools/port_metrics.py`. Оригинал и адаптированный код читаются по контракту",
        "раскладки (docs/LAYOUT.md, `tools/codesys/stlayout.py`); сравниваются одноимённые объекты",
        "(имена без учёта регистра, переименования — `--map СТАРОЕ=НОВОЕ`), внутри объекта — файлы",
        "одной роли: объявление, тело, метод, свойство, аксессор.",
        "",
        "**Строка.** Считаются значимые строки: непустые после удаления комментариев (с",
        "`--with-comments` комментарии остаются). Маркеры `// PORT:` вырезаются всегда: пометка правки",
        "сама правкой не считается. Прагмы `{attribute ...}` остаются — они меняют поведение компилятора.",
        "Пробелы и отступы не различаются: строки сравниваются после схлопывания пробелов.",
        "",
        "**Разложение строк оригинала** (в сумме — 100 % строк оригинала). Пары строк сопоставляет",
        "`difflib.SequenceMatcher` (без эвристики autojunk):",
        "",
        *_header("Корзина", "Что попадает"),
        _row("без изменений", "строка оригинала есть в адаптированном файле в том же порядке"),
        _row("изменена", "строка оригинала в заменённом участке (`replace`)"),
        _row("переписана", "все строки оригинала в файле со статусом «переписан»"),
        _row(
            "удалена / не перенесена",
            "строка удалённого участка (`delete`) и все строки файлов, которых нет в адаптированном коде",
        ),
        _row(
            "добавлено (отдельно, не входит в 100 %)",
            "вставки (`insert`), прирост заменённых участков и переписанных файлов, файлы и объекты,"
            " которых нет в оригинале",
        ),
        "",
        "**Различие файла** d = 1 − (строк без изменений) / max(строк оригинала, строк адаптированного).",
        "Файл **переписан**, если он есть в обеих версиях, в обеих есть значимые строки и d больше порога",
        "(параметр `--threshold`, по умолчанию 0,5: тело POU, отличающееся больше чем наполовину, —",
        "переписано). Ровно на пороге — «изменён». Статус объекта считается той же формулой по сумме его",
        "файлов; строки по корзинам раскладываются на уровне файлов.",
        "",
        *_header("Статус", "Файл", "Объект"),
        _row("без изменений", "значимые строки совпадают", "все файлы без изменений"),
        _row("изменён", "есть правки, d ≤ порога", "есть правки, d по сумме файлов ≤ порога"),
        _row("переписан", "d > порога", "d по сумме файлов > порога"),
        _row("новый", "файла нет в оригинале", "объекта нет в оригинале (адаптер, замена)"),
        _row("не перенесён", "файла нет в адаптированном коде", "объекта нет в адаптированном коде"),
        "",
        "**Маркер правки** — комментарий `// PORT: [категория] причина` в строке правки или в",
        "комментарии непосредственно над ней (для удалённого участка — в соседних строках). Метка",
        "в квадратных скобках необязательна: без неё категория определяется по ключевым словам причины,",
        "иначе — `other`. Маркеры в блочных комментариях `(* *)` не распознаются.",
        "",
        "**Маркер проверки** — `// PORT: [категория] проверить в Astra.IDE — что (пункт)`: код оставлен в",
        "форме CODESYS, потому что поведение Astra.IDE по документации вендора не подтверждено. Это не",
        "правка: такой маркер не помечает участок правки и не считается лишним. Расстановку маркеров",
        "проверки по правилам ведёт `tools/port_checks.py`; пункт в скобках — раздел 9 чек-листа миграции.",
        "",
        "**Пары деревьев.** Адаптированное дерево с той же меткой, что у оригинала (`--orig МЕТКА=…`,",
        "`--adapted МЕТКА=…`), сравнивается только с ним: у библиотеки и флагмана есть одноимённые объекты.",
        "",
        "**Категория строк.** Строки участка правки относятся к категории первого маркера правки в его",
        "окне, новый или переписанный файл — к первому маркеру правки файла (без него — объекта).",
        "«Строк оригинала затронуто» — изменённые, переписанные и удалённые строки участков; «добавлено» —",
        "строки адаптированного кода в участках правок и новых файлах.",
        "",
        "Проверка пометок (с `--strict` нарушения дают код выхода 1):",
        "",
        "- участок правок в изменённом файле без маркера в своих строках;",
        "- переписанный файл, новый файл перенесённого объекта, новый объект — без единого маркера",
        "  (новому объекту достаточно одного маркера в любом файле, обычно в объявлении);",
        "- неизвестная метка категории или маркер без причины;",
        "- маркер, не относящийся ни к одной правке, — только предупреждение (правку откатили, маркер забыли).",
        "",
        "Удалённые файлы и объекты пометить нельзя: они перечислены в таблице файлов со статусом",
        "«не перенесён», причину пишут в README и `docs/differences.md`.",
        "",
        "**Категории причин** (метка — по-английски, в квадратных скобках):",
        "",
        *_header("Метка", "Причина правки"),
    ]
    lines += [_row(f"`{cat.tag}`", cat.title) for cat in CATEGORIES]
    lines.append("")
    return lines


def _counts_row(title: str, c: LineCounts, n: int) -> str:
    return _row(
        title,
        n,
        c.orig,
        _cell(c.unchanged, c.orig),
        _cell(c.changed, c.orig),
        _cell(c.rewritten, c.orig),
        _cell(c.removed, c.orig),
        c.added,
        c.adapted,
    )


def _summary_md(report: Report) -> list[str]:
    out = [
        "## Итог",
        "",
        "Проценты — от строк оригинала в той же строке таблицы.",
        "",
        *_header(
            "Источник",
            "Объектов",
            "Строк оригинала",
            "Без изменений",
            "Изменено",
            "Переписано",
            "Удалено / не перенесено",
            "Добавлено",
            "Строк после переноса",
        ),
    ]
    out += [_counts_row(f"`{label}`", counts, n) for label, counts, n in report.by_label()]
    out.append(_counts_row("**Итого**", report.totals(), len(report.objects)))
    out += ["", *_header("Статус", "Объектов", "Файлов")]
    for status in STATUSES:
        n_obj = sum(1 for o in report.objects if o.status == status)
        n_file = sum(1 for f in report.files if f.status == status)
        out.append(_row(STATUS_TITLES[status], n_obj, n_file))
    out.append("")
    return out


def _markers_md(report: Report) -> list[str]:
    out = ["## Правки по категориям", ""]
    stats = category_stats(report)
    if not report.markers:
        return [*out, "Маркеров нет.", ""]
    out += [
        "Маркер правки — `// PORT: [категория] причина` у изменённого кода; маркер проверки —",
        "`// PORT: [категория] проверить в Astra.IDE — …` у кода, оставленного в форме CODESYS, пока",
        "пункт чек-листа не проверен в среде. Строки участка правки относятся к категории его маркера.",
        "",
        *_header(
            "Категория",
            "Причина",
            "Маркеров правки",
            "Объектов с правками",
            "Файлов с правками",
            "Строк оригинала затронуто",
            "Строк добавлено",
            "Маркеров проверки",
        ),
    ]
    titles = {cat.tag: cat.title for cat in CATEGORIES}
    for st in stats:
        out.append(
            _row(
                f"`{st.tag}`",
                titles[st.tag],
                st.changes,
                len(st.objects),
                len(st.files),
                st.orig_lines,
                st.added_lines,
                st.checks,
            )
        )
    all_objects = set().union(*(st.objects for st in stats)) if stats else set()
    all_files = set().union(*(st.files for st in stats)) if stats else set()
    out.append(
        _row(
            "**Всего**",
            "",
            len(report.change_markers),
            len(all_objects),
            len(all_files),
            sum(st.orig_lines for st in stats),
            sum(st.added_lines for st in stats),
            len(report.check_markers),
        )
    )
    implicit = sum(1 for m in report.markers if not m.explicit)
    if implicit:
        out += ["", f"Маркеров без метки (категория по ключевым словам причины): {implicit}."]
    out.append("")
    items = check_items(report)
    if items:
        out += [
            "### Маркеры проверки по пунктам чек-листа",
            "",
            "Пункты — раздел 9 `docs/migration_checklist.md`. Когда пункт подтверждён в Astra.IDE, его маркеры",
            'снимает `python tools/port_checks.py --resolve <пункт> --note "…"`; если не подтверждён — код',
            "переписывается, и маркеры проверки сменяются маркерами правки.",
            "",
            *_header("Пункт", "Маркеров проверки", "Категории"),
        ]
        out += [_row(item, n, ", ".join(f"`{t}`" for t in tags)) for item, n, tags in items]
        out.append("")
    return out


def _checks_md(report: Report) -> list[str]:
    out = ["## Проверка пометок", ""]
    unmarked = report.unmarked
    bad = [m for m in report.markers if m.unknown_tag or not m.reason]
    stale = report.stale_markers
    if not (unmarked or bad or stale):
        return [*out, "Все правки помечены, лишних маркеров нет.", ""]
    if unmarked:
        out += ["Правки без маркера `// PORT:`:", "", *_header("Файл:строка", "Вид", "Текст")]
        out += [_row(f"`{f.display}:{h.line}`", HUNK_TITLES[h.kind], _snippet(h.text)) for f, h in unmarked]
        out.append("")
    if bad:
        out += ["Маркеры с неизвестной категорией или без причины:", "", *_header("Файл:строка", "Метка", "Причина")]
        out += [_row(f"`{m.path}:{m.line}`", f"`{m.raw_tag or ''}`", _md_escape(m.reason) or "—") for m in bad]
        out.append("")
    if stale:
        out += ["Маркеры, не относящиеся ни к одной правке (предупреждение):", "", *_header("Файл:строка", "Причина")]
        out += [_row(f"`{m.path}:{m.line}`", _md_escape(m.reason) or "—") for m in stale]
        out.append("")
    return out


def _objects_md(report: Report) -> list[str]:
    out = [
        "## По объектам",
        "",
        *_header(
            "Объект",
            "Источник",
            "Статус",
            "Строк оригинала",
            "Без изменений",
            "Изменено",
            "Переписано",
            "Удалено",
            "Добавлено",
            "Различие",
            "PORT",
        ),
    ]
    for obj in report.objects:
        c = obj.counts
        name = obj.name if not obj.orig_name or obj.orig_name == obj.name else f"{obj.name} ← {obj.orig_name}"
        out.append(
            _row(
                f"`{name}`",
                obj.label,
                STATUS_TITLES[obj.status],
                c.orig,
                c.unchanged,
                c.changed,
                c.rewritten,
                c.removed,
                c.added,
                _ratio(c.difference),
                obj.markers,
            )
        )
    out.append("")
    return out


def _files_md(report: Report) -> list[str]:
    files = [f for f in report.files if f.status != STATUS_UNCHANGED]
    same = len(report.files) - len(files)
    out = ["## По файлам", ""]
    if same:
        out.append(f"Файлы без изменений ({same}) в таблицу не выводятся — они есть в `port_metrics.json`.")
    else:
        out.append("Файлов без изменений нет.")
    out.append("")
    if not files:
        return out
    out += _header(
        "Файл",
        "Статус",
        "Строк было",
        "Строк стало",
        "Без изменений",
        "Изменено",
        "Переписано",
        "Удалено",
        "Добавлено",
        "Различие",
        "PORT",
    )
    for f in files:
        c = f.counts
        out.append(
            _row(
                f"`{f.display}`",
                STATUS_TITLES[f.status],
                c.orig,
                c.adapted,
                c.unchanged,
                c.changed,
                c.rewritten,
                c.removed,
                c.added,
                _ratio(c.difference),
                len(f.markers),
            )
        )
    out.append("")
    return out


def render_md(report: Report) -> str:
    """Отчёт docs/port_metrics.md."""
    origs = "; ".join(f"`{s.label}` — `{s.display}`" for s in report.origs)
    line_kind = "значимая строка с комментариями" if report.with_comments else "значимая строка кода (без комментариев)"
    out: list[str] = [
        "# Метрики переноса",
        "",
        "<!-- Файл создаёт tools/port_metrics.py; правки вручную перезаписываются при следующем запуске. -->",
        "",
        "Сколько кода CODESYS 3.5.17.30 перенесено в Astra.IDE без изменений, сколько изменено и",
        "переписано. Трудозатраты в часах — в README (их записывает инженер).",
        "",
        *_header("Параметр", "Значение"),
        _row("Оригинал", origs),
        _row("Адаптированный код", "; ".join(f"`{s.display}`" for s in report.adapted)),
        _row("Строка", line_kind),
        _row("Порог «переписан»", f"различие файла больше {_ratio(report.threshold)}"),
    ]
    if report.command:
        out.append(_row("Команда", f"`{_md_escape(report.command)}`"))
    out.append("")
    out += _summary_md(report)
    out += _markers_md(report)
    out += _checks_md(report)
    out += _objects_md(report)
    out += _files_md(report)
    if report.warnings:
        out += ["## Предупреждения", ""]
        out += [f"- {_md_escape(w)}" for w in report.warnings]
        out.append("")
    out += methodology_md()
    return "\n".join(out).rstrip("\n") + "\n"


def render_json(report: Report) -> str:
    """Отчёт docs/port_metrics.json (машиночитаемый, все файлы)."""
    by_category: dict[str, dict[str, int]] = {}
    for marker in report.markers:
        slot = by_category.setdefault(marker.tag, {"markers": 0, "implicit": 0, "changes": 0, "checks": 0})
        slot["markers"] += 1
        slot["implicit"] += 0 if marker.explicit else 1
        slot["checks" if marker.check else "changes"] += 1
    data: dict[str, object] = {
        "schema": SCHEMA_VERSION,
        "params": {"threshold": report.threshold, "with_comments": report.with_comments, "command": report.command},
        "orig": [{"label": s.label, "path": s.display} for s in report.origs],
        "adapted": [{"label": s.label, "path": s.display} for s in report.adapted],
        "totals": report.totals().to_json(),
        "by_source": [{"source": label, "objects": n, **c.to_json()} for label, c, n in report.by_label()],
        "status_counts": {
            "objects": {s: sum(1 for o in report.objects if o.status == s) for s in STATUSES},
            "files": {s: sum(1 for f in report.files if f.status == s) for s in STATUSES},
        },
        "markers": {
            "total": len(report.markers),
            "changes": len(report.change_markers),
            "checks": len(report.check_markers),
            "by_category": {cat.tag: by_category[cat.tag] for cat in CATEGORIES if cat.tag in by_category},
            "check_items": {item: n for item, n, _ in check_items(report)},
            "items": [m.to_json() for m in report.markers],
        },
        "categories": [st.to_json() for st in category_stats(report)],
        "unmarked": [h.to_json(f.display) for f, h in report.unmarked],
        "stale_markers": [{"path": m.path, "line": m.line, "reason": m.reason} for m in report.stale_markers],
        "objects": [o.to_json() for o in report.objects],
        "files": [{"object": o.name, **f.to_json()} for o in report.objects for f in o.files],
        "warnings": report.warnings,
    }
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


# ---------------------------------------------------------------------------
# Командная строка
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="port_metrics.py",
        description="Метрики переноса: строки без изменений, изменённые и переписанные; маркеры // PORT:.",
    )
    parser.add_argument(
        "--orig",
        action="append",
        metavar="[МЕТКА=]КАТАЛОГ",
        help="раскладка оригинала (каталог src); можно повторять. По умолчанию — снимки upstream/kns-pump-station/src"
        " и upstream/plc-process-lib/src (с исключением plc-process-lib:PRG_Main)",
    )
    parser.add_argument(
        "--adapted",
        action="append",
        metavar="[МЕТКА=]КАТАЛОГ",
        help="раскладка адаптированного кода; можно повторять. По умолчанию targets/astra/src и"
        " targets/astra/lib/src (метки — как у оригиналов)",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=DEFAULT_THRESHOLD,
        help="порог различия файла для статуса «переписан», доля 0..1 (по умолчанию 0.5)",
    )
    parser.add_argument("--with-comments", action="store_true", help="считать и строки комментариев")
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        metavar="ШАБЛОН",
        help="не сравнивать объекты: имя или МЕТКА:имя, шаблон fnmatch без учёта регистра; можно повторять",
    )
    parser.add_argument(
        "--map",
        action="append",
        default=[],
        metavar="СТАРОЕ=НОВОЕ",
        help="объект переименован при переносе; можно повторять",
    )
    parser.add_argument("--md", default=DEFAULT_MD, help="отчёт Markdown (по умолчанию docs/port_metrics.md)")
    parser.add_argument("--json", default=DEFAULT_JSON, help="отчёт JSON (по умолчанию docs/port_metrics.json)")
    parser.add_argument("--dry-run", action="store_true", help="только посчитать и вывести итог, файлы не писать")
    parser.add_argument(
        "--check",
        action="store_true",
        help="не писать отчёты, а сравнить с существующими: код 1, если они устарели",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="код выхода 1 при правках без маркера, неизвестной категории или маркере без причины",
    )
    parser.add_argument("-q", "--quiet", action="store_true", help="без итогового сообщения")
    return parser


def _parse_renames(items: Sequence[str]) -> list[tuple[str, str]]:
    result = []
    for item in items:
        old, sep, new = item.partition("=")
        if not sep or not old.strip() or not new.strip():
            raise UsageError(f"--map: ожидается СТАРОЕ=НОВОЕ, получено {item!r}")
        result.append((old.strip(), new.strip()))
    return result


def command_line(
    origs: Sequence[Source], adapted: Sequence[Source], args: argparse.Namespace, exclude: Sequence[str] = ()
) -> str:
    """Команда для отчёта: только входные параметры, пути — относительно репозитория.

    Пути вывода (--md, --json) в команду не попадают: в отчёте не остаётся путей пользователя.
    """
    parts = ["python", "tools/port_metrics.py"]
    for flag, sources in (("--orig", origs), ("--adapted", adapted)):
        for source in sources:
            parts += [flag, f"{source.label}={source.display}"]
    if args.threshold != DEFAULT_THRESHOLD:
        parts += ["--threshold", str(args.threshold)]
    if args.with_comments:
        parts.append("--with-comments")
    for pattern in exclude:
        parts += ["--exclude", pattern]
    for item in args.map:
        parts += ["--map", item]
    if args.strict:
        parts.append("--strict")
    return " ".join(f'"{part}"' if " " in part else part for part in parts)


def summary(report: Report) -> str:
    t = report.totals()
    return (
        f"port_metrics: строк оригинала {t.orig} — без изменений {_pct(t.unchanged, t.orig)}, "
        f"изменено {_pct(t.changed, t.orig)}, переписано {_pct(t.rewritten, t.orig)}, "
        f"удалено {_pct(t.removed, t.orig)}; добавлено {t.added}; маркеров PORT {len(report.markers)} "
        f"(правок {len(report.change_markers)}, проверок {len(report.check_markers)}), "
        f"правок без маркера {len(report.unmarked)}"
    )


def configure_output() -> None:
    """Вывод в UTF-8 и при перенаправлении в файл или канал (Windows по умолчанию — cp1251)."""
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="replace")


def main(argv: Sequence[str] | None = None) -> int:
    configure_output()
    args_list = list(sys.argv[1:] if argv is None else argv)
    parser = build_parser()
    try:
        args = parser.parse_args(args_list)
    except SystemExit as exc:  # --help — 0, ошибка аргументов — 2
        return 0 if exc.code in (0, None) else 2
    base = REPO_ROOT
    # Исключения по умолчанию относятся к деревьям по умолчанию
    exclude = list(args.exclude) or ([] if args.orig else list(DEFAULT_EXCLUDE))
    try:
        origs = [parse_source(s, base) for s in (args.orig or DEFAULT_ORIGS)]
        adapted = [parse_source(s, base) for s in (args.adapted or DEFAULT_ADAPTED)]
        report, errors = build_report(
            origs,
            adapted,
            threshold=args.threshold,
            with_comments=args.with_comments,
            exclude=exclude,
            renames=_parse_renames(args.map),
            base=base,
        )
    except UsageError as exc:
        print(f"port_metrics: {exc}", file=sys.stderr)
        return 2
    if errors:
        for err in errors:
            print(err, file=sys.stderr)
        print(f"port_metrics: ошибки раскладки ({len(errors)}), отчёт не записан", file=sys.stderr)
        return 1
    report.command = command_line(origs, adapted, args, exclude)
    for warning in report.warnings:
        print(f"предупреждение: {warning}", file=sys.stderr)
    outputs = ((os.path.abspath(args.md), render_md(report)), (os.path.abspath(args.json), render_json(report)))
    stale = False
    if args.check:
        for path, text in outputs:
            current = L.read_text(path) if os.path.exists(path) else None
            if current != text:
                stale = True
                print(f"port_metrics: отчёт устарел: {_display_path(path, base)}", file=sys.stderr)
    elif not args.dry_run:
        for path, text in outputs:
            L.write_text(path, text)
    if not args.quiet:
        print(summary(report))
    if args.strict:
        problems = report.strict_problems()
        for problem in problems:
            print(problem, file=sys.stderr)
        if problems:
            return 1
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main())
