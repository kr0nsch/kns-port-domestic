#!/usr/bin/env python3
"""Инвентаризация возможностей CODESYS в исходниках ST — основа оценки переноса на Astra.IDE.

Читает одно или несколько деревьев исходников в раскладке docs/LAYOUT.md (через stlayout) и находит,
какие возможности CODESYS используются и где: ООП, прагмы и атрибуты, библиотеки по пространствам
имён, типы данных, конструкции языка, RETAIN/PERSISTENT, привязку AT %I/%Q/%M, задачи из
tools/codesys/config.json и идентификаторы, зарезервированные в других средах МЭК. Каждой
возможности сопоставлены риск для Astra.IDE и ссылки на исследование (tools/inventory_catalog.py).

Результат: docs/inventory.md (для чтения) и docs/inventory.json (для port_metrics и автоматизации).
Источники и пути вывода — tools/inventory.toml; путь и ревизию источника можно переопределить
переменной окружения из настроек или ключом --source ID=ПУТЬ[@РЕВИЗИЯ].

Ревизия git (по умолчанию HEAD; можно список — берётся первая существующая) читается из
репозитория командой git archive: незафиксированные и неотслеживаемые файлы рабочих копий в отчёт
не попадают, а коммит записывается в отчёт; если коммит выгружен в рабочую копию (в том числе в
другой git worktree) и там есть незафиксированные изменения, отчёт об этом предупреждает.
Ревизия «worktree» — рабочее дерево как есть. Объекты, побайтно совпадающие с базовой линией
(пример шаблона plc-repo-template), пропускаются: это не код проекта.

Коды выхода: 0 — успех, 1 — ошибка чтения источников или настроек, 2 — неверные аргументы.
"""

from __future__ import annotations

import argparse
import html
import io
import json
import os
import re
import subprocess
import sys
import tarfile
import tomllib
from collections import Counter, defaultdict
from collections.abc import Iterable, Sequence
from contextlib import ExitStack
from dataclasses import dataclass, field
from pathlib import PurePosixPath
from tempfile import TemporaryDirectory
from typing import Any

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(TOOLS_DIR)
sys.path.insert(0, os.path.join(TOOLS_DIR, "codesys"))
sys.path.insert(0, TOOLS_DIR)

import inventory_catalog as C  # noqa: E402
import stlayout as L  # noqa: E402

SCHEMA = "kns-port-domestic/inventory/1"
DEFAULT_CONFIG = "tools/inventory.toml"
CONFIG_JSON = "tools/codesys/config.json"
WORKTREE = "worktree"
MAX_FILES_IN_MD = 25
MAX_NAMES_IN_CELL = 8
MAX_DETAILS_IN_CELL = 6

SUBDIR_ORDER = ("src", "tests")

# Роли файлов раскладки: суффикс -> роль; главный файл объекта не имеет члена (member = "")
_SUFFIX_ROLES = (
    (L.SUFFIX_METHOD_DECL, "method_decl"),
    (L.SUFFIX_METHOD_IMPL, "method_impl"),
    (L.SUFFIX_PROP_DECL, "prop_decl"),
    (L.SUFFIX_GET_DECL, "get_decl"),
    (L.SUFFIX_GET_IMPL, "get_impl"),
    (L.SUFFIX_SET_DECL, "set_decl"),
    (L.SUFFIX_SET_IMPL, "set_impl"),
    (L.SUFFIX_DUT, "dut"),
    (L.SUFFIX_GVL, "gvl"),
    (L.SUFFIX_PVL, "pvl"),
    (L.SUFFIX_ITF, "itf"),
    (L.SUFFIX_DECL, "decl"),
    (L.SUFFIX_IMPL, "impl"),
)
_MAIN_ROLES = frozenset({"dut", "gvl", "pvl", "itf", "decl", "impl"})
DECL_ROLES = frozenset({"dut", "gvl", "pvl", "itf", "decl", "method_decl", "prop_decl", "get_decl", "set_decl"})

_ACCESS = {
    "PUBLIC": "oop.access_public",
    "PRIVATE": "oop.access_private",
    "PROTECTED": "oop.access_protected",
    "INTERNAL": "oop.access_internal",
}
_DUNDER = {
    "__NEW": "construct.new",
    "__DELETE": "construct.new",
    "__QUERYINTERFACE": "oop.queryinterface",
    "__QUERYPOINTER": "oop.queryinterface",
    "__ISVALIDREF": "construct.isvalidref",
    "__TRY": "construct.try",
    "__XINT": "type.xint",
    "__UXINT": "type.xint",
    "__XWORD": "type.xint",
    "__SYSTEM": "construct.system",
}
_DUNDER_SKIP = frozenset({"__CATCH", "__FINALLY", "__ENDTRY"})  # части блока __TRY
_INT64 = frozenset({"LINT", "ULINT", "LWORD"})
_LDATE = frozenset({"LDATE", "LTOD", "LDT", "LDATE_AND_TIME", "LTIME_OF_DAY"})
_LDATE_PREFIXES = frozenset({"LD", "LDATE", "LDT", "LTOD", "LDATE_AND_TIME", "LTIME_OF_DAY"})
_ANY = frozenset(
    {
        "ANY",
        "ANY_NUM",
        "ANY_INT",
        "ANY_REAL",
        "ANY_BIT",
        "ANY_STRING",
        "ANY_DATE",
        "ANY_ELEMENTARY",
        "ANY_MAGNITUDE",
        "ANY_DERIVED",
    }
)
_LTIME_CONV_RE = re.compile(r"\A(?:[A-Z0-9_]+_TO_LTIME|LTIME_TO_[A-Z0-9_]+|TO_LTIME)\Z")
_SUBRANGE_RE = re.compile(r"\A[A-Za-z_][A-Za-z0-9_]*\s*\([^()]*\.\.[^()]*\)\Z")
_ATTRIBUTE_RE = re.compile(r"\Aattribute\s+'([^']*)'(?:\s*:=\s*'([^']*)')?", re.IGNORECASE)
_VENDOR_PREFIX_RE = re.compile(r"\APs[A-Z]")
# Интерфейс по правилам именования (CONTRIBUTING.md): I_<Имя>. Нужен для типов из библиотек, которые
# не сканировались (например, PL.I_Motor во флагмане без источника библиотеки).
_ITF_NAME_RE = re.compile(r"\AI_[A-Za-z0-9]")
_TYPE_POSITION_WORDS = frozenset({"OF", "TO", "EXTENDS"})


class InventoryError(Exception):
    """Ошибка чтения источников или настроек (код выхода 1)."""


# ---------------------------------------------------------------------------
# Настройки
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class TreeSpec:
    """Дерево исходников: каталог и ревизии git по порядку (берётся первая существующая).

    Пустой кортеж ревизий — рабочее дерево как есть.
    """

    path: str
    revs: tuple[str, ...]


@dataclass(frozen=True)
class SourceSpec:
    id: str
    title: str
    tree: TreeSpec
    dirs: tuple[str, ...]
    baseline: str | None


@dataclass(frozen=True)
class BaselineSpec:
    id: str
    title: str
    tree: TreeSpec


@dataclass(frozen=True)
class Config:
    sources: tuple[SourceSpec, ...]
    baselines: dict[str, BaselineSpec]
    markdown: str
    json: str


def _env_or(table: dict[str, Any], key: str, env: dict[str, str]) -> Any:
    """Значение key, если не задана непустая переменная окружения из key + '_env'."""
    env_name = table.get(key + "_env")
    if isinstance(env_name, str) and env.get(env_name):
        return env[env_name]
    return table.get(key)


def parse_revs(value: Any) -> tuple[str, ...]:
    """rev из настроек: строка, строка через запятую или список; «worktree» или пусто — рабочее дерево."""
    if value is None:
        return ("HEAD",)
    if isinstance(value, str):
        items = value.split(",")
    elif isinstance(value, list) and all(isinstance(v, str) for v in value):
        items = list(value)
    else:
        raise InventoryError(f"rev: ожидалась строка или список строк, получено {value!r}")
    revs = tuple(v.strip() for v in items if v.strip())
    if not revs or revs == (WORKTREE,):
        return ()
    if WORKTREE in revs:
        raise InventoryError(f"rev: «{WORKTREE}» нельзя сочетать с ревизиями git: {value!r}")
    return revs


def _tree(table: dict[str, Any], what: str, env: dict[str, str]) -> TreeSpec:
    path = _env_or(table, "path", env)
    if not isinstance(path, str) or not path:
        raise InventoryError(f"{what}: не задан path")
    return TreeSpec(path, parse_revs(_env_or(table, "rev", env)))


def parse_config(data: dict[str, Any], env: dict[str, str] | None = None) -> Config:
    """Разбирает настройки (содержимое tools/inventory.toml)."""
    env = dict(os.environ) if env is None else env
    known = {"output", "source", "baseline"}
    unknown = sorted(set(data) - known)
    if unknown:
        raise InventoryError(f"неизвестные разделы настроек: {', '.join(unknown)}")
    baselines: dict[str, BaselineSpec] = {}
    for bid, table in sorted(data.get("baseline", {}).items()):
        if not isinstance(table, dict):
            raise InventoryError(f"baseline.{bid}: ожидалась таблица")
        baselines[bid] = BaselineSpec(bid, str(table.get("title", bid)), _tree(table, f"baseline.{bid}", env))
    sources: list[SourceSpec] = []
    seen: set[str] = set()
    for table in data.get("source", []):
        sid = table.get("id")
        if not isinstance(sid, str) or not re.fullmatch(r"[a-z][a-z0-9_-]*", sid):
            raise InventoryError(f"source: id должен быть коротким именем [a-z0-9_-], получено {sid!r}")
        if sid in seen:
            raise InventoryError(f"source: id {sid} повторяется")
        seen.add(sid)
        dirs = table.get("dirs", ["src", "tests"])
        if not isinstance(dirs, list) or not all(isinstance(d, str) and d for d in dirs):
            raise InventoryError(f"source.{sid}: dirs — список каталогов")
        baseline = table.get("baseline")
        if baseline is not None and baseline not in baselines:
            raise InventoryError(f"source.{sid}: нет базовой линии {baseline!r}")
        sources.append(
            SourceSpec(sid, str(table.get("title", sid)), _tree(table, f"source.{sid}", env), tuple(dirs), baseline)
        )
    if not sources:
        raise InventoryError("в настройках нет ни одного [[source]]")
    output = data.get("output", {})
    return Config(
        tuple(sources),
        baselines,
        str(output.get("markdown", "docs/inventory.md")),
        str(output.get("json", "docs/inventory.json")),
    )


def load_config(path: str, env: dict[str, str] | None = None) -> Config:
    try:
        with open(path, "rb") as handle:
            data = tomllib.load(handle)
    except FileNotFoundError as exc:
        raise InventoryError(f"нет файла настроек {path}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise InventoryError(f"{path}: {exc}") from exc
    return parse_config(data, env)


def override_source(config: Config, spec: str) -> Config:
    """--source ID=ПУТЬ[@РЕВИЗИЯ]: заменяет путь (и ревизию) источника или базовой линии.

    Неизвестный ID добавляет новый источник (каталоги src и tests, без базовой линии); без
    @РЕВИЗИИ он читается как рабочее дерево.
    """
    sid, sep, rest = spec.partition("=")
    if not sep or not sid or not rest:
        raise InventoryError(f"--source: ожидалось ID=ПУТЬ[@РЕВИЗИЯ], получено {spec!r}")
    path, at, rev_text = rest.rpartition("@")
    if not at or not path:
        path, at, rev_text = rest, "", ""
    sources = list(config.sources)
    for i, src in enumerate(sources):
        if src.id == sid:
            revs = parse_revs(rev_text) if at else src.tree.revs
            sources[i] = SourceSpec(src.id, src.title, TreeSpec(path, revs), src.dirs, src.baseline)
            return Config(tuple(sources), config.baselines, config.markdown, config.json)
    if sid in config.baselines:
        base = config.baselines[sid]
        revs = parse_revs(rev_text) if at else base.tree.revs
        baselines = dict(config.baselines)
        baselines[sid] = BaselineSpec(base.id, base.title, TreeSpec(path, revs))
        return Config(config.sources, baselines, config.markdown, config.json)
    if not re.fullmatch(r"[a-z][a-z0-9_-]*", sid):
        raise InventoryError(f"--source: id должен быть коротким именем [a-z0-9_-], получено {sid!r}")
    revs = parse_revs(rev_text) if at else ()
    sources.append(SourceSpec(sid, sid, TreeSpec(path, revs), SUBDIR_ORDER, None))
    return Config(tuple(sources), config.baselines, config.markdown, config.json)


# ---------------------------------------------------------------------------
# Чтение деревьев (рабочая копия или ревизия git)
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class Snapshot:
    """Прочитанное дерево: где лежат файлы и что это за ревизия."""

    display_path: str
    root: str
    rev: str | None
    commit: str | None
    commit_date: str | None
    dirty: bool | None  # в рабочей копии с этим коммитом есть незафиксированные изменения
    dirty_worktree: str | None = None  # какая рабочая копия проверялась (путь для отчёта)


def display_path(path: str, base_dir: str) -> str:
    """Путь для отчёта: относительно корня репозитория (без путей пользователя), через '/'."""
    full = os.path.normpath(os.path.join(base_dir, path))
    try:
        rel = os.path.relpath(full, base_dir)
    except ValueError:  # другой диск в Windows
        return os.path.basename(full)
    return rel.replace(os.sep, "/")


def _git(repo: str, *args: str) -> str:
    try:
        proc = subprocess.run(["git", "-C", repo, *args], capture_output=True, text=True, encoding="utf-8", check=False)
    except FileNotFoundError as exc:
        raise InventoryError("git не найден: ревизии читаются через git archive") from exc
    if proc.returncode != 0:
        raise InventoryError(f"git {' '.join(args)} ({repo}): {proc.stderr.strip()}")
    return proc.stdout


def _extract_tar(data: bytes, dest: str) -> None:
    """Распаковывает tar из git archive: только обычные файлы, без абсолютных путей и '..'."""
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
        for member in tar.getmembers():
            if not member.isfile():
                continue
            parts = PurePosixPath(member.name).parts
            if member.name.startswith("/") or ".." in parts or not parts:
                raise InventoryError(f"недопустимый путь в архиве git: {member.name}")
            handle = tar.extractfile(member)
            if handle is None:
                continue
            target = os.path.join(dest, *parts)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            with open(target, "wb") as out:
                out.write(handle.read())


def _resolve(repo: str, shown: str, revs: Sequence[str]) -> tuple[str, str]:
    """Первая существующая ревизия из revs: (ревизия, коммит)."""
    errors: list[str] = []
    for rev in revs:
        try:
            return rev, _git(repo, "rev-parse", "--verify", "--quiet", rev + "^{commit}").strip()
        except InventoryError as exc:
            errors.append(f"{rev}: {exc}")
    tried = ", ".join(revs)
    raise InventoryError(f"{shown}: нет ни одной из ревизий {tried} или это не репозиторий git ({'; '.join(errors)})")


def checked_out_worktree(repo: str, rev: str, commit: str) -> str | None:
    """Рабочая копия (git worktree), в которую выгружена ревизия.

    Ветка rev — та рабочая копия, где она выгружена; HEAD — сам repo; иначе любая рабочая копия
    с этим коммитом (своя — в первую очередь).
    """
    entries: list[dict[str, str]] = []
    for line in _git(repo, "worktree", "list", "--porcelain").splitlines():
        key, _, value = line.partition(" ")
        if key == "worktree":
            entries.append({"path": value})
        elif entries and key in ("HEAD", "branch"):
            entries[-1][key] = value.strip()
    own = os.path.normcase(os.path.normpath(repo))

    def is_own(entry: dict[str, str]) -> bool:
        return os.path.normcase(os.path.normpath(entry["path"])) == own

    for entry in entries:
        if entry.get("branch") == "refs/heads/" + rev:
            return entry["path"]
    if rev == "HEAD":
        return repo
    same = [e for e in entries if e.get("HEAD") == commit]
    same.sort(key=lambda e: not is_own(e))
    return same[0]["path"] if same else None


def load_tree(tree: TreeSpec, paths: Sequence[str], base_dir: str, stack: ExitStack) -> Snapshot:
    """Готовит дерево: рабочая копия как есть или файлы paths ревизии git во временном каталоге."""
    repo = os.path.normpath(os.path.join(base_dir, tree.path))
    shown = display_path(tree.path, base_dir)
    if not os.path.isdir(repo):
        raise InventoryError(f"нет каталога {shown}")
    if not tree.revs:
        return Snapshot(shown, repo, None, None, None, None)
    rev, commit = _resolve(repo, shown, tree.revs)
    date = _git(repo, "show", "-s", "--format=%cs", commit).strip()
    dirty: bool | None = None
    worktree = checked_out_worktree(repo, rev, commit)
    worktree_shown: str | None = None
    if worktree is not None:
        dirty = bool(_git(worktree, "status", "--porcelain", "--", *paths).strip())
        worktree_shown = display_path(worktree, base_dir)
    tmp = stack.enter_context(TemporaryDirectory(prefix="inventory-"))
    present = [p for p in _git(repo, "ls-tree", "--name-only", commit, "--", *paths).splitlines() if p]
    if present:
        try:
            proc = subprocess.run(
                ["git", "-C", repo, "archive", "--format=tar", commit, "--", *present],
                capture_output=True,
                check=False,
            )
        except FileNotFoundError as exc:  # pragma: no cover - git уже вызывался выше
            raise InventoryError("git не найден") from exc
        if proc.returncode != 0:
            raise InventoryError(f"git archive ({shown}): {proc.stderr.decode('utf-8', 'replace').strip()}")
        _extract_tar(proc.stdout, tmp)
    return Snapshot(shown, tmp, rev, commit, date, dirty, worktree_shown)


# ---------------------------------------------------------------------------
# Файлы объектов и объявления
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class SourceFile:
    """Файл объекта раскладки: путь от корня источника, текст, роль, член (метод или свойство)."""

    path: str
    text: str
    role: str
    member: str


def object_source_files(obj: L.StObject) -> list[SourceFile]:
    files: list[SourceFile] = []
    for rel, text in L.object_files(obj):
        base = rel.rsplit("/", 1)[-1]
        for suffix, role in _SUFFIX_ROLES:
            if base.endswith(suffix):
                member = "" if role in _MAIN_ROLES else base[: -len(suffix)]
                files.append(SourceFile(rel, text, role, member))
                break
    return files


@dataclass(frozen=True, order=True)
class Occurrence:
    """Одно вхождение возможности: где (источник, файл, строка, объект, член) и подробность."""

    feature: str
    source: str
    subdir: str
    path: str
    line: int
    obj: str
    member: str = ""
    detail: str = ""


@dataclass(frozen=True)
class Decl:
    """Объявленное имя: объект, метод, свойство, переменная, поле структуры, значение перечисления."""

    name: str
    kind: str
    source: str
    subdir: str
    path: str
    line: int
    obj: str
    member: str


def _header(obj: L.StObject) -> L.DeclHeader | None:
    return obj.header or L.parse_header(obj.decl)


def collect_decls(source: str, obj: L.StObject) -> list[Decl]:
    """Все имена, объявленные объектом (для проверки зарезервированных слов и затенения имён)."""
    out: list[Decl] = []
    files = object_source_files(obj)
    main = files[0]
    hdr = _header(obj)
    out.append(Decl(obj.name, "объект", source, obj.subdir, main.path, hdr.line if hdr else 1, obj.name, ""))
    by_member = {(f.member, f.role): f for f in files}
    for method in obj.methods:
        mf = by_member.get((method.name, "method_decl"))
        mh = method.header or L.parse_header(method.decl)
        path = mf.path if mf else main.path
        out.append(Decl(method.name, "метод", source, obj.subdir, path, mh.line if mh else 1, obj.name, method.name))
    for prop in obj.properties:
        pf = by_member.get((prop.name, "prop_decl"))
        ph = prop.header or L.parse_header(prop.decl)
        path = pf.path if pf else main.path
        out.append(Decl(prop.name, "свойство", source, obj.subdir, path, ph.line if ph else 1, obj.name, prop.name))
    for f in files:
        if f.role not in DECL_ROLES:
            continue
        tokens = L.tokenize(f.text)
        for block in L.parse_var_blocks(f.text, tokens):
            for decl in block.decls:
                for name, index in decl.names:
                    out.append(
                        Decl(name, "переменная", source, obj.subdir, f.path, tokens[index].line, obj.name, f.member)
                    )
        if f.role == "dut":
            tdecl = L.parse_type_decl(f.text, tokens)
            if tdecl is None:
                continue
            for member in tdecl.members:
                for name, index in member.names:
                    out.append(Decl(name, "поле", source, obj.subdir, f.path, tokens[index].line, obj.name, ""))
            for name, _value, index in tdecl.enum_values:
                out.append(Decl(name, "значение", source, obj.subdir, f.path, tokens[index].line, obj.name, ""))
    return out


# ---------------------------------------------------------------------------
# Поиск возможностей
# ---------------------------------------------------------------------------


def _base_type(type_text: str) -> str:
    """Последнее (возможно, составное) имя в тексте типа: 'ARRAY [1..2] OF PL.I_Motor' -> 'PL.I_Motor'."""
    tokens = L.tokenize(type_text)
    sig = [tokens[i] for i in L.significant_indices(tokens)]
    last = ""
    k = 0
    while k < len(sig):
        tok = sig[k]
        if tok.kind == L.TK_IDENT:
            parts = [tok.text]
            while k + 2 < len(sig) and sig[k + 1].is_op(".") and sig[k + 2].kind == L.TK_IDENT:
                parts.append(sig[k + 2].text)
                k += 2
            last = ".".join(parts)
        k += 1
    return last


class Detector:
    """Находит вхождения возможностей в объектах одного источника."""

    def __init__(self, source: str, interfaces: set[str], shadow: set[str]) -> None:
        self.source = source
        self.interfaces = interfaces  # имена интерфейсов (верхний регистр)
        self.shadow = shadow  # объявленные имена (верхний регистр): не путать с POU библиотек
        self.found: list[Occurrence] = []

    def add(self, fid: str, obj: L.StObject, path: str, line: int, member: str = "", detail: str = "") -> None:
        self.found.append(Occurrence(fid, self.source, obj.subdir, path, line, obj.name, member, detail))

    # --- объект целиком: заголовки, методы, свойства, DUT ---

    def scan_object(self, obj: L.StObject) -> None:
        files = object_source_files(obj)
        main = files[0]
        hdr = _header(obj)
        line = hdr.line if hdr else 1
        by_member = {(f.member, f.role): f for f in files}
        if obj.kind == L.KIND_ITF:
            self.add("oop.interface", obj, main.path, line)
            for base in hdr.extends if hdr else []:
                self.add("oop.interface_extends", obj, main.path, line, detail=base)
        elif obj.kind == L.KIND_POU and hdr is not None:
            if obj.name.upper() in C.CHECK_POUS:
                self.add("construct.check_pou", obj, main.path, line, detail=obj.name)
            for base in hdr.extends:
                self.add("oop.extends_fb", obj, main.path, line, detail=base)
            if hdr.implements:
                self.add("oop.implements", obj, main.path, line, detail=", ".join(hdr.implements))
            self._modifiers(obj, main.path, line, "", hdr.modifiers, "POU", access=False)
        elif obj.kind == L.KIND_DUT:
            self._dut(obj, main)
        elif obj.kind == L.KIND_PVL:
            self.add("retain.pvl", obj, main.path, 1)
        elif obj.kind == L.KIND_GVL:
            self._gvl(obj, main)
        is_itf = obj.kind == L.KIND_ITF
        for method in obj.methods:
            mf = by_member.get((method.name, "method_decl"))
            mh = method.header or L.parse_header(method.decl)
            path = mf.path if mf else main.path
            mline = mh.line if mh else 1
            self.add("oop.method_itf" if is_itf else "oop.method", obj, path, mline, method.name)
            if not is_itf:
                self._modifiers(obj, path, mline, method.name, mh.modifiers if mh else [], "метод")
            upper = method.name.upper()
            if upper == "FB_INIT":
                self.add("oop.fb_init", obj, path, mline, method.name)
            elif upper in ("FB_EXIT", "FB_REINIT"):
                self.add("oop.fb_exit", obj, path, mline, method.name, method.name)
        for prop in obj.properties:
            pf = by_member.get((prop.name, "prop_decl"))
            ph = prop.header or L.parse_header(prop.decl)
            path = pf.path if pf else main.path
            pline = ph.line if ph else 1
            self.add("oop.property_itf" if is_itf else "oop.property", obj, path, pline, prop.name)
            if not is_itf:
                self._modifiers(obj, path, pline, prop.name, ph.modifiers if ph else [], "свойство")
            for has, kind, fid in (
                (prop.has_get, "get", "oop.property_get"),
                (prop.has_set, "set", "oop.property_set"),
            ):
                if not has:
                    continue
                af = by_member.get((prop.name, kind + "_impl")) or by_member.get((prop.name, kind + "_decl"))
                self.add(fid, obj, af.path if af else path, 1 if af else pline, prop.name)

    def _modifiers(
        self,
        obj: L.StObject,
        path: str,
        line: int,
        member: str,
        modifiers: Sequence[str],
        what: str,
        access: bool = True,
    ) -> None:
        specifiers = [m for m in modifiers if m in _ACCESS]
        for spec in specifiers:
            self.add(_ACCESS[spec], obj, path, line, member, what)
        if access and not specifiers:
            self.add("oop.access_default", obj, path, line, member, what)
        if "ABSTRACT" in modifiers:
            self.add("oop.abstract", obj, path, line, member, what)
        if "FINAL" in modifiers:
            self.add("oop.final", obj, path, line, member, what)

    def _dut(self, obj: L.StObject, main: SourceFile) -> None:
        tdecl = L.parse_type_decl(main.text)
        if tdecl is None:
            return
        line = tdecl.header.line
        kind = tdecl.kind
        if kind == "struct":
            self.add("type.struct", obj, main.path, line)
            for base in tdecl.header.extends:
                self.add("type.struct_extends", obj, main.path, line, detail=base)
        elif kind == "union":
            self.add("type.union", obj, main.path, line)
        elif kind == "enum":
            self.add("type.enum", obj, main.path, line)
            if tdecl.enum_base_type:
                self.add("type.enum_base", obj, main.path, line, detail=tdecl.enum_base_type)
        elif kind == "alias":
            self.add("type.alias", obj, main.path, line, detail=tdecl.alias_type or "")
            if tdecl.alias_type and _SUBRANGE_RE.match(tdecl.alias_type):
                self.add("type.subrange", obj, main.path, line, detail=tdecl.alias_type)
        for member in tdecl.members:
            self._decl_type(obj, main.path, "", member)

    def _gvl(self, obj: L.StObject, main: SourceFile) -> None:
        tokens = L.tokenize(main.text)
        blocks = [b for b in L.parse_var_blocks(main.text, tokens) if b.keyword == "VAR_GLOBAL"]
        constant = [b for b in blocks if "CONSTANT" in b.modifiers]
        if constant and len(constant) < len(blocks):
            self.add("construct.gvl_mixed", obj, main.path, tokens[constant[0].keyword_index].line)

    # --- файл: прагмы, токены, секции переменных ---

    def scan_file(self, obj: L.StObject, f: SourceFile) -> None:
        tokens = L.tokenize(f.text)
        for tok in tokens:
            if tok.kind == L.TK_PRAGMA:
                self._pragma(obj, f, tok)
        self._tokens(obj, f, tokens)
        if f.role in DECL_ROLES:
            self._var_blocks(obj, f, tokens)

    def _pragma(self, obj: L.StObject, f: SourceFile, tok: L.Token) -> None:
        body = tok.text[1:-1].strip() if tok.text.endswith("}") else tok.text[1:].strip()
        match = _ATTRIBUTE_RE.match(body)
        if match:
            name = match.group(1).strip()
            value = match.group(2)
            fid = C.attribute_feature(name).id
            self.add(fid, obj, f.path, tok.line, f.member, value if value is not None else "")
            return
        word = body.split(None, 1)[0].lower() if body else ""
        if word == "if":
            self.add("pragma.conditional", obj, f.path, tok.line, f.member, body)
        elif word in ("elsif", "else", "end_if"):
            return
        elif word in ("warning", "error", "info", "messageguid"):
            self.add("pragma.message", obj, f.path, tok.line, f.member, word)
        else:
            self.add("pragma.other", obj, f.path, tok.line, f.member, word or body)

    def _tokens(self, obj: L.StObject, f: SourceFile, tokens: list[L.Token]) -> None:
        sig = L.significant_indices(tokens)
        n = len(sig)
        for k, ti in enumerate(sig):
            tok = tokens[ti]
            prev = tokens[sig[k - 1]] if k > 0 else None
            nxt = tokens[sig[k + 1]] if k + 1 < n else None
            nxt2 = tokens[sig[k + 2]] if k + 2 < n else None
            fid, detail = self._classify(tok, prev, nxt, nxt2, tokens[ti + 1] if ti + 1 < len(tokens) else None)
            if fid:
                self.add(fid, obj, f.path, tok.line, f.member, detail)

    def _classify(
        self,
        tok: L.Token,
        prev: L.Token | None,
        nxt: L.Token | None,
        nxt2: L.Token | None,
        adjacent: L.Token | None,
    ) -> tuple[str, str]:
        """Возможность для значимого токена (с соседями) или ('', '')."""
        kind = tok.kind
        if kind == L.TK_TYPED:
            prefix = tok.text.split("#", 1)[0].upper()
            if prefix in ("LT", "LTIME"):
                return "type.ltime_literal", ""
            if prefix in _INT64:
                return "type.int64", prefix
            if prefix in _LDATE_PREFIXES:
                return "type.ldate", prefix
            return "", ""
        if kind == L.TK_WSTRING:
            return "type.wstring", "литерал"
        if kind == L.TK_ADDRESS:
            address = tok.text.upper()
            if prev is not None and prev.is_ident("AT"):
                if "*" in address:
                    return "io.at_wildcard", address
                if address[1:2] == "M":
                    return "io.at_memory", address
                return "io.at_fixed", address
            return "io.direct", address
        if kind == L.TK_OP:
            if tok.text == "^" and not (prev is not None and prev.is_ident("SUPER", "THIS")):
                return "construct.deref", ""
            return "", ""
        if kind != L.TK_IDENT:
            return "", ""
        word = tok.upper
        after_dot = prev is not None and prev.is_op(".")
        nxt_open = nxt is not None and nxt.is_op("(")
        if (
            not after_dot
            and word in C.NAMESPACES
            and word not in self.shadow
            and nxt is not None
            and nxt.is_op(".")
            and nxt2 is not None
            and nxt2.kind == L.TK_IDENT
        ):
            return C.NAMESPACES[word], f"{tok.text}.{nxt2.text}"
        if word in ("SUPER", "THIS") and nxt is not None and nxt.is_op("^"):
            if word == "THIS":
                return "oop.this", ""
            body = nxt2 is not None and nxt2.is_op("(")
            return "oop.super", "SUPER^(…) — тело базы" if body else "SUPER^.метод"
        if word.startswith("__"):
            if word in _DUNDER_SKIP:
                return "", ""
            return _DUNDER.get(word, "construct.dunder_other"), word
        if word in ("REFERENCE", "POINTER") and nxt is not None and nxt.is_ident("TO"):
            return ("type.reference" if word == "REFERENCE" else "type.pointer"), ""
        if word == "ARRAY" and nxt is not None and nxt.is_op("[") and nxt2 is not None and nxt2.is_op("*"):
            return "type.array_varlen", ""
        if after_dot:
            return "", ""
        if word == "LTIME":
            return ("construct.ltime_op", "") if nxt_open else ("type.ltime", "")
        if word == "TIME" and nxt_open:
            return "construct.time_op", ""
        if _LTIME_CONV_RE.match(word):
            return "type.ltime_conv", word
        if word in _INT64:
            return "type.int64", word
        if word == "WSTRING":
            return "type.wstring", "тип"
        if word in _LDATE:
            return "type.ldate", word
        if word in _ANY:
            return "type.any", word
        type_position = prev is not None and (prev.is_op(":") or prev.is_ident(*_TYPE_POSITION_WORDS))
        if word == "BIT" and type_position:
            return "type.bit", ""
        if nxt_open and word in ("ADR", "SIZEOF", "BITADR"):
            return "construct." + word.lower(), ""
        if word == "REF" and adjacent is not None and adjacent.is_op("=") and adjacent.pos == tok.end:
            return "construct.ref_assign", ""
        if word in self.shadow or (nxt is not None and nxt.is_op(".")):
            return "", ""
        if word in C.LIBRARY_POUS and (nxt_open or type_position):
            return C.LIBRARY_POUS[word], tok.text
        if nxt_open:
            for prefix, fid in C.SYSTEM_FUNCTION_PREFIXES:
                if word.startswith(prefix) and len(word) > len(prefix):
                    return fid, tok.text
        return "", ""

    def _var_blocks(self, obj: L.StObject, f: SourceFile, tokens: list[L.Token]) -> None:
        for block in L.parse_var_blocks(f.text, tokens):
            line = tokens[block.keyword_index].line
            keyword = block.keyword
            mods = block.modifiers
            if keyword == "VAR_IN_OUT":
                fid = "construct.var_in_out_const" if "CONSTANT" in mods else "construct.var_in_out"
                self.add(fid, obj, f.path, line, f.member)
            elif keyword in ("VAR_STAT", "VAR_INST", "VAR_TEMP", "VAR_EXTERNAL"):
                self.add("construct." + keyword.lower(), obj, f.path, line, f.member)
            elif keyword == "VAR" and "CONSTANT" in mods:
                self.add("construct.var_constant", obj, f.path, line, f.member)
            elif keyword == "VAR_GLOBAL" and "CONSTANT" in mods:
                self.add("construct.gvl_constant", obj, f.path, line, f.member)
            for decl in block.decls:
                names = ", ".join(decl.name_list)
                if "PERSISTENT" in mods:
                    self.add("retain.persistent", obj, f.path, decl.line, f.member, names)
                elif "RETAIN" in mods:
                    self.add("retain.retain", obj, f.path, decl.line, f.member, names)
                elif "NON_RETAIN" in mods:
                    self.add("retain.non_retain", obj, f.path, decl.line, f.member, names)
                self._decl_type(obj, f.path, f.member, decl)

    def _decl_type(self, obj: L.StObject, path: str, member: str, decl: L.VarDecl) -> None:
        """Тип объявления (переменной или поля структуры): интерфейс, поддиапазон."""
        base_full = _base_type(decl.type_text)
        base = base_full.split(".")[-1]
        if base and (base.upper() in self.interfaces or _ITF_NAME_RE.match(base)):
            self.add("oop.itf_var", obj, path, decl.line, member, base_full)
        if _SUBRANGE_RE.match(decl.type_text):
            self.add("type.subrange", obj, path, decl.line, member, decl.type_text)


# ---------------------------------------------------------------------------
# Источники: чтение, базовая линия, задачи, статистика
# ---------------------------------------------------------------------------


@dataclass
class TaskRow:
    source: str
    mode: str
    name: str
    interval_ms: Any
    priority: Any
    pous: list[str]
    line: int
    remark: str


@dataclass
class LibraryRow:
    source: str
    key: str
    label: str
    version: str
    namespace: str
    modes: list[str]
    feature: str


@dataclass
class SourceData:
    spec: SourceSpec
    snap: Snapshot
    objects: list[L.StObject] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)
    issues: list[L.LayoutIssue] = field(default_factory=list)
    config: dict[str, Any] | None = None
    baseline_title: str = ""
    skipped_tasks: list[str] = field(default_factory=list)  # задачи только с объектами базовой линии


def scan_objects(root: str, dirs: Iterable[str]) -> tuple[list[L.StObject], list[L.LayoutIssue]]:
    objects: list[L.StObject] = []
    issues: list[L.LayoutIssue] = []
    for subdir in dirs:
        result = L.scan(root, subdir)
        objects.extend(result.objects)
        issues.extend(result.issues)
    return objects, issues


def _read_config_json(root: str) -> dict[str, Any] | None:
    path = os.path.join(root, *CONFIG_JSON.split("/"))
    if not os.path.isfile(path):
        return None
    try:
        data = json.loads(L.read_text(path))
    except ValueError as exc:
        raise InventoryError(f"{CONFIG_JSON}: {exc}") from exc
    return data if isinstance(data, dict) else None


def task_remark(priority: Any) -> str:
    """Замечание по приоритету задачи для REGUL (R13, F04)."""
    if priority is None:
        return (
            "приоритет в config.json не задан (CODESYS ставит своё значение по умолчанию); на REGUL "
            "задать явно: 2–15 на ЦП I/III типа, 5–15 на ЦП II типа"
        )
    try:
        value = int(priority)
    except (TypeError, ValueError):
        return f"приоритет {priority!r} — не число"
    if value < 2:
        return f"приоритет {value}: на REGUL 0 и 1 зарезервированы — переназначить"
    if value > 15:
        return f"приоритет {value}: на REGUL максимум 15 — переназначить"
    if value < 5:
        return f"приоритет {value}: допустим на ЦП I/III типа, на ЦП II типа — от 5"
    return f"приоритет {value}: допустим на REGUL"


def _json_line(text: str, needle: str) -> int:
    pos = text.find(needle)
    return text.count("\n", 0, pos) + 1 if pos >= 0 else 1


def collect_tasks(data: SourceData) -> tuple[list[TaskRow], list[LibraryRow]]:
    """Задачи и ссылки на библиотеки из tools/codesys/config.json источника.

    Задача, все POU которой — пропущенные объекты базовой линии (PRG_Main примера шаблона), не
    считается: это настройка шаблона, а не проекта. Источник без своих объектов не даёт и ссылок на
    библиотеки — они тоже из шаблона.
    """
    cfg = data.config
    data.skipped_tasks = []
    if cfg is None:
        return [], []
    skipped = {name.upper() for name in data.skipped}
    path = os.path.join(data.snap.root, *CONFIG_JSON.split("/"))
    text = L.read_text(path)
    tasks: list[TaskRow] = []
    modes = cfg.get("modes", {})
    used: dict[str, list[str]] = defaultdict(list)
    common = cfg.get("library", {}).get("libraries", []) if isinstance(cfg.get("library"), dict) else []
    for mode in sorted(modes):
        mcfg = modes[mode]
        if not isinstance(mcfg, dict):
            continue
        for task in mcfg.get("tasks", []):
            name = str(task.get("name", ""))
            pous = [str(p) for p in task.get("pous", [])]
            if pous and all(p.upper() in skipped for p in pous):
                data.skipped_tasks.append(f"{mode}/{name}")
                continue
            tasks.append(
                TaskRow(
                    data.spec.id,
                    mode,
                    name,
                    task.get("interval_ms"),
                    task.get("priority"),
                    pous,
                    _json_line(text, json.dumps(name)),
                    task_remark(task.get("priority")),
                )
            )
        for key in list(mcfg.get("libraries", [])) + list(common):
            if mode not in used[key]:
                used[key].append(mode)
    libraries: list[LibraryRow] = []
    if not data.objects:
        return tasks, libraries
    for key, lib in sorted(cfg.get("libraries", {}).items()):
        if key.startswith("_") or not isinstance(lib, dict):
            continue
        namespace = str(lib.get("namespace") or lib.get("placeholder") or key)
        libraries.append(
            LibraryRow(
                data.spec.id,
                key,
                str(lib.get("label") or lib.get("title") or key),
                str(lib.get("version", "")),
                namespace,
                sorted(used.get(key, [])),
                C.NAMESPACES.get(namespace.upper(), ""),
            )
        )
    return tasks, libraries


def _baseline_files(objects: Iterable[L.StObject]) -> dict[str, str]:
    files: dict[str, str] = {}
    for obj in objects:
        for rel, text in L.object_files(obj):
            files[rel] = text
    return files


def load_source(
    spec: SourceSpec,
    config: Config,
    base_dir: str,
    stack: ExitStack,
    use_baseline: bool = True,
) -> SourceData:
    snap = load_tree(spec.tree, [*spec.dirs, CONFIG_JSON], base_dir, stack)
    data = SourceData(spec, snap)
    objects, data.issues = scan_objects(snap.root, spec.dirs)
    data.config = _read_config_json(snap.root)
    if use_baseline and spec.baseline is not None:
        base = config.baselines[spec.baseline]
        bsnap = load_tree(base.tree, [*spec.dirs, CONFIG_JSON], base_dir, stack)
        bobjects, _ = scan_objects(bsnap.root, spec.dirs)
        bfiles = _baseline_files(bobjects)
        data.baseline_title = base.title
        for obj in objects:
            if all(bfiles.get(rel) == text for rel, text in L.object_files(obj)):
                data.skipped.append(obj.name)
            else:
                data.objects.append(obj)
    else:
        data.objects = objects
    return data


@dataclass
class Stats:
    """Объём кода одного каталога раскладки источника."""

    objects: Counter[str] = field(default_factory=Counter)
    methods: int = 0
    properties: int = 0
    files: int = 0
    lines: int = 0
    code_lines: int = 0

    def to_json(self) -> dict[str, Any]:
        return {
            "objects": dict(sorted(self.objects.items())),
            "methods": self.methods,
            "properties": self.properties,
            "files": self.files,
            "lines": self.lines,
            "code_lines": self.code_lines,
        }


OBJECT_KINDS = (
    ("dut", "DUT"),
    ("gvl", "GVL"),
    ("pvl", "PVL"),
    ("itf", "интерфейсы"),
    ("function", "FUNCTION"),
    ("function_block", "FUNCTION_BLOCK"),
    ("program", "PROGRAM"),
)


def code_lines(text: str) -> int:
    """Строки, в которых есть хотя бы один значимый токен (не пробел, комментарий или прагма)."""
    tokens = L.tokenize(text)
    lines: set[int] = set()
    for i in L.significant_indices(tokens):
        tok = tokens[i]
        lines.update(range(tok.line, tok.line + tok.text.count("\n") + 1))
    return len(lines)


def source_stats(data: SourceData) -> dict[str, Stats]:
    stats: dict[str, Stats] = {}
    for obj in data.objects:
        st = stats.setdefault(obj.subdir, Stats())
        st.objects[obj.pou_kind or obj.kind] += 1
        st.methods += len(obj.methods)
        st.properties += len(obj.properties)
        for _, text in L.object_files(obj):
            st.files += 1
            st.lines += text.count("\n")
            st.code_lines += code_lines(text)
    return dict(sorted(stats.items(), key=lambda kv: _subdir_key(kv[0])))


def _subdir_key(subdir: str) -> tuple[int, str]:
    return (SUBDIR_ORDER.index(subdir) if subdir in SUBDIR_ORDER else len(SUBDIR_ORDER), subdir)


# ---------------------------------------------------------------------------
# Инвентаризация целиком
# ---------------------------------------------------------------------------


@dataclass
class Inventory:
    sources: list[SourceData]
    occurrences: list[Occurrence]
    decls: list[Decl]
    tasks: list[TaskRow]
    libraries: list[LibraryRow]

    def source_ids(self) -> list[str]:
        return [s.spec.id for s in self.sources]


def analyze(sources: list[SourceData]) -> Inventory:
    """Две стадии: объявления всех источников (затенение имён, интерфейсы), затем вхождения."""
    decls: list[Decl] = []
    interfaces: set[str] = set()
    for data in sources:
        for obj in data.objects:
            decls.extend(collect_decls(data.spec.id, obj))
            if obj.kind == L.KIND_ITF:
                interfaces.add(obj.name.upper())
    shadow = {d.name.upper() for d in decls}
    found: list[Occurrence] = []
    tasks: list[TaskRow] = []
    libraries: list[LibraryRow] = []
    for data in sources:
        det = Detector(data.spec.id, interfaces, shadow)
        for obj in data.objects:
            det.scan_object(obj)
            for f in object_source_files(obj):
                det.scan_file(obj, f)
        found.extend(det.found)
        t, lib = collect_tasks(data)
        tasks.extend(t)
        libraries.extend(lib)
        for row in t:
            found.append(
                Occurrence("task.config", data.spec.id, "config", CONFIG_JSON, row.line, row.mode, row.name, row.name)
            )
    for d in decls:
        upper = d.name.upper()
        for fid, _title, words, _src in C.RESERVED_SETS:
            if upper in words:
                found.append(Occurrence(fid, d.source, d.subdir, d.path, d.line, d.obj, d.member, d.name))
        if d.kind == "объект" and _VENDOR_PREFIX_RE.match(d.name):
            found.append(Occurrence("ident.vendor_prefix", d.source, d.subdir, d.path, d.line, d.obj, "", d.name))
    found.sort()
    return Inventory(sources, found, decls, tasks, libraries)


def feature_ids(inv: Inventory) -> list[str]:
    """Порядок возможностей в отчёте: группа, атрибуты по имени, затем порядок справочника."""
    attrs = sorted({o.feature for o in inv.occurrences if o.feature.startswith("attr.")})
    ordered: list[str] = []
    for group, _title in C.GROUPS:
        if group == "pragma":
            ordered.extend(attrs)
        ordered.extend(f.id for f in C.FEATURES.values() if f.group == group)
    return ordered


@dataclass
class FeatureSummary:
    feature: C.Feature
    counts: dict[str, dict[str, int]]  # источник -> каталог -> число
    objects: dict[str, list[str]]  # источник -> объекты
    details: Counter[str]
    files: list[tuple[str, str, str, list[int]]]  # (источник, путь, объект, строки)

    @property
    def total(self) -> int:
        return sum(sum(by_dir.values()) for by_dir in self.counts.values())


def summarize(inv: Inventory) -> list[FeatureSummary]:
    by_feature: dict[str, list[Occurrence]] = defaultdict(list)
    for occ in inv.occurrences:
        by_feature[occ.feature].append(occ)
    out: list[FeatureSummary] = []
    for fid in feature_ids(inv):
        occs = by_feature.get(fid, [])
        counts: dict[str, dict[str, int]] = {}
        objects: dict[str, set[str]] = defaultdict(set)
        details: Counter[str] = Counter()
        files: dict[tuple[str, str], tuple[str, list[int]]] = {}
        for occ in occs:
            by_dir = counts.setdefault(occ.source, {})
            by_dir[occ.subdir] = by_dir.get(occ.subdir, 0) + 1
            objects[occ.source].add(occ.obj)
            if occ.detail:
                details[occ.detail] += 1
            key = (occ.source, occ.path)
            _obj, lines = files.setdefault(key, (occ.obj, []))
            if occ.line not in lines:
                lines.append(occ.line)
        file_list = [(src, path, obj, sorted(lines)) for (src, path), (obj, lines) in sorted(files.items())]
        out.append(
            FeatureSummary(
                C.feature(fid),
                counts,
                {src: sorted(names, key=lambda n: (n.lower(), n)) for src, names in sorted(objects.items())},
                details,
                file_list,
            )
        )
    return out


# ---------------------------------------------------------------------------
# Отчёт Markdown
# ---------------------------------------------------------------------------


def _cell(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ")


def _ref_link(ref: str) -> str:
    anchor = re.sub(r"[^a-z0-9]", "", ref.lower()) or "ref"
    return f"[{ref}](#ref-{anchor})"


def _refs(refs: Sequence[str]) -> str:
    return ", ".join(_ref_link(r) for r in refs) if refs else "—"


def _names(names: Sequence[str], limit: int = MAX_NAMES_IN_CELL) -> str:
    shown = ", ".join(f"`{n}`" for n in names[:limit])
    rest = len(names) - limit
    return shown + (f" и ещё {rest}" if rest > 0 else "")


def _details(details: Counter[str]) -> str:
    items = sorted(details.items(), key=lambda kv: (-kv[1], kv[0].lower(), kv[0]))
    parts = [f"`{_cell(d)}`" + (f" ×{n}" if n > 1 else "") for d, n in items[:MAX_DETAILS_IN_CELL]]
    rest = len(items) - MAX_DETAILS_IN_CELL
    return ", ".join(parts) + (f" и ещё {rest}" if rest > 0 else "")


def _count_cell(summary: FeatureSummary, source: str) -> str:
    by_dir = summary.counts.get(source, {})
    if not by_dir:
        return "—"
    if set(by_dir) <= set(SUBDIR_ORDER):
        return " / ".join(str(by_dir.get(d, 0)) for d in SUBDIR_ORDER)
    return ", ".join(f"{n}" for _, n in sorted(by_dir.items()))


def _objects_cell(summary: FeatureSummary, inv: Inventory) -> str:
    titles = {s.spec.id: s.spec.title for s in inv.sources}
    parts = []
    for src, names in summary.objects.items():
        prefix = f"{titles.get(src, src)}: " if len(summary.objects) > 1 else ""
        parts.append(prefix + _names(names))
    return "; ".join(parts)


def _source_rows(inv: Inventory) -> list[str]:
    rows = [
        "| Источник | Путь | Ревизия | Каталоги | Объектов | Примечание |",
        "|---|---|---|---|---|---|",
    ]
    for data in inv.sources:
        snap = data.snap
        rev = f"`{snap.rev}` = `{snap.commit[:7]}` ({snap.commit_date})" if snap.commit else "рабочее дерево"
        notes = []
        if snap.dirty:
            notes.append(
                f"в рабочей копии `{snap.dirty_worktree}` есть незафиксированные изменения в "
                f"{', '.join(data.spec.dirs)} — в отчёт не попали (читается коммит)"
            )
        if data.skipped:
            notes.append(f"{len(data.skipped)} объектов совпадают с базовой линией «{data.baseline_title}» и пропущены")
        if not data.objects:
            notes.append("**собственных исходников пока нет**")
        if data.skipped_tasks:
            notes.append(
                "задачи config.json только с объектами базовой линии пропущены: "
                + ", ".join(f"`{t}`" for t in data.skipped_tasks)
            )
        if data.issues:
            notes.append(f"замечаний раскладки: {len(data.issues)}")
        rows.append(
            f"| {_cell(data.spec.title)} | `{snap.display_path}` | {rev} | {', '.join(data.spec.dirs)} | "
            f"{len(data.objects)} | {_cell('; '.join(notes)) or '—'} |"
        )
    return rows


def _stats_rows(inv: Inventory) -> list[str]:
    head = "| Источник | Каталог | " + " | ".join(t for _, t in OBJECT_KINDS)
    head += " | Методы | Свойства | Файлов | Строк | Строк кода |"
    rows = [head, "|" + "---|" * (len(OBJECT_KINDS) + 7)]
    for data in inv.sources:
        stats = source_stats(data)
        if not stats:
            rows.append(f"| {_cell(data.spec.title)} | — |" + " 0 |" * (len(OBJECT_KINDS) + 5))
            continue
        for subdir, st in stats.items():
            cells = " | ".join(str(st.objects.get(k, 0)) for k, _ in OBJECT_KINDS)
            rows.append(
                f"| {_cell(data.spec.title)} | `{subdir}` | {cells} | {st.methods} | {st.properties} | "
                f"{st.files} | {st.lines} | {st.code_lines} |"
            )
    return rows


def _feature_table(summaries: Sequence[FeatureSummary], inv: Inventory) -> list[str]:
    titles = [s.spec.title for s in inv.sources]
    head = "| Возможность | Ед. | " + " | ".join(f"{_cell(t)}: src / tests" for t in titles)
    head += " | Риск | Ссылки | Что делать при переносе | Где (объекты) | Подробности |"
    rows = [head, "|" + "---|" * (len(titles) + 7)]
    for s in summaries:
        f = s.feature
        counts = " | ".join(_count_cell(s, sid) for sid in inv.source_ids())
        rows.append(
            f"| {f.title} | {f.unit} | {counts} | {f.risk} | {_refs(f.refs)} | {_cell(f.action)} | "
            f"{_objects_cell(s, inv)} | {_details(s.details)} |"
        )
    return rows


def _top_risks(summaries: Sequence[FeatureSummary], inv: Inventory) -> list[str]:
    risky = [s for s in summaries if s.total and C.RISK_ORDER.get(s.feature.risk, 0) >= C.RISK_ORDER[C.RISK_MEDIUM]]
    risky.sort(key=lambda s: (-C.RISK_ORDER[s.feature.risk], -s.total, s.feature.id))
    if not risky:
        return ["Возможностей со средним и высоким риском не найдено."]
    titles = [s.spec.title for s in inv.sources]
    head = "| Риск | Возможность | " + " | ".join(f"{_cell(t)}: src / tests" for t in titles)
    head += " | Ссылки | Что делать |"
    rows = [head, "|" + "---|" * (len(titles) + 4)]
    for s in risky:
        counts = " | ".join(_count_cell(s, sid) for sid in inv.source_ids())
        rows.append(
            f"| {s.feature.risk} | {s.feature.title} | {counts} | {_refs(s.feature.refs)} | {_cell(s.feature.action)} |"
        )
    return rows


def _task_rows(inv: Inventory) -> list[str]:
    titles = {s.spec.id: s.spec.title for s in inv.sources}
    lines: list[str] = []
    if inv.tasks:
        lines += [
            "| Источник | Режим | Задача | Интервал, мс | Приоритет | POU | Замечание для REGUL |",
            "|---|---|---|---|---|---|---|",
        ]
        for t in inv.tasks:
            prio = "—" if t.priority is None else str(t.priority)
            lines.append(
                f"| {_cell(titles[t.source])} | `{t.mode}` | `{t.name}` | {t.interval_ms} | {prio} | "
                f"{_names(t.pous)} | {_cell(t.remark)} |"
            )
    else:
        lines.append("Задач в `tools/codesys/config.json` источников не найдено (или они как в базовой линии).")
    if inv.libraries:
        lines += [
            "",
            "Ссылки на библиотеки в `tools/codesys/config.json`:",
            "",
            "| Источник | Ключ | Библиотека | Версия | Пространство имён | Режимы | Риск | Ссылки |",
            "|---|---|---|---|---|---|---|---|",
        ]
        for lib in inv.libraries:
            feat = C.feature(lib.feature) if lib.feature else None
            risk = feat.risk if feat else "—"
            refs = _refs(feat.refs) if feat else "—"
            modes = ", ".join(f"`{m}`" for m in lib.modes) or "—"
            lines.append(
                f"| {_cell(titles[lib.source])} | `{lib.key}` | {_cell(lib.label)} | {lib.version or '—'} | "
                f"`{lib.namespace}` | {modes} | {risk} | {refs} |"
            )
    return lines


def _identifier_rows(inv: Inventory) -> list[str]:
    reserved = [o for o in inv.occurrences if o.feature in ("ident.rusty", "ident.iec_checker")]
    if not reserved:
        return ["Объявленных имён, зарезервированных в RuSTy 1.0.6 и iec_checker 0.4, нет."]
    by_name: dict[str, dict[str, Any]] = {}
    kinds = {(d.source, d.path, d.line, d.name): d.kind for d in inv.decls}
    titles = {fid: title for fid, title, _w, _s in C.RESERVED_SETS}
    for o in reserved:
        entry = by_name.setdefault(o.detail.upper(), {"tools": set(), "kinds": set(), "where": set(), "places": set()})
        entry["tools"].add(titles[o.feature])
        entry["kinds"].add(kinds.get((o.source, o.path, o.line, o.detail), "имя"))
        entry["where"].add(o.obj + (f".{o.member}" if o.member else ""))
        entry["places"].add((o.source, o.path, o.line))
    rows = ["| Имя | Где зарезервировано | Что это | Объявлений | Где |", "|---|---|---|---|---|"]
    for name in sorted(by_name):
        e = by_name[name]
        rows.append(
            f"| `{name}` | {', '.join(sorted(e['tools']))} | {', '.join(sorted(e['kinds']))} | "
            f"{len(e['places'])} | {_names(sorted(e['where']))} |"
        )
    return rows


def is_researched(feature: C.Feature) -> bool:
    """Есть ли у возможности факт, риск или раздел исследования (пункт чек-листа — не в счёт)."""
    return any(C.ref_kind(ref) != "checklist" for ref in feature.refs)


def _unresearched(summaries: Sequence[FeatureSummary]) -> list[str]:
    missing = [s for s in summaries if s.total and not is_researched(s.feature) and s.feature.risk != C.RISK_NONE]
    if not missing:
        return ["Все найденные возможности покрыты исследованием."]
    rows = ["| Возможность | Риск | Вхождений | Чек-лист | Что сделать |", "|---|---|---|---|---|"]
    for s in missing:
        checks = [r for r in s.feature.refs if C.ref_kind(r) == "checklist"]
        check = _refs(checks) if checks else "добавить пункт"
        rows.append(f"| {s.feature.title} | {s.feature.risk} | {s.total} | {check} | {_cell(s.feature.action)} |")
    return rows


def _html_inline(text: str) -> str:
    """Markdown-код `x` -> <code>x</code> (внутри HTML-тегов вроде <summary> Markdown не работает)."""
    return re.sub(r"`([^`]*)`", r"<code>\1</code>", html.escape(text, quote=False))


def _where(summaries: Sequence[FeatureSummary], inv: Inventory, json_name: str) -> list[str]:
    titles = {s.spec.id: s.spec.title for s in inv.sources}
    lines: list[str] = []
    for s in summaries:
        if not s.total:
            continue
        lines += [f"<details><summary>{_html_inline(s.feature.title)} — {s.total}</summary>", ""]
        shown = s.files[:MAX_FILES_IN_MD]
        for src in sorted({f[0] for f in shown}, key=inv.source_ids().index):
            lines.append(f"{titles[src]}:")
            lines.append("")
            for fsrc, path, obj, numbers in shown:
                if fsrc == src:
                    lines.append(f"- `{path}` ({obj}): {', '.join(str(n) for n in numbers)}")
            lines.append("")
        rest = len(s.files) - len(shown)
        if rest > 0:
            lines += [f"… и ещё {rest} файлов — полный список в `{json_name}`.", ""]
        lines += ["</details>", ""]
    return lines


def _used_refs(summaries: Sequence[FeatureSummary], inv: Inventory) -> list[str]:
    refs: set[str] = set()
    for s in summaries:
        if s.total:
            refs.update(s.feature.refs)
    for lib in inv.libraries:
        if lib.feature:
            refs.update(C.feature(lib.feature).refs)
    return sorted(refs, key=_ref_sort_key)


def _ref_sort_key(ref: str) -> tuple[int, str, int]:
    order = {"fact": 0, "risk": 1, "checklist": 2, "section": 3}[C.ref_kind(ref)]
    match = re.match(r"([^0-9]*)([0-9.]*)", ref)
    prefix, number = (match.group(1), match.group(2)) if match else (ref, "")
    try:
        num = int(number.split(".")[0]) if number else 0
    except ValueError:
        num = 0
    return order, prefix, num


def _references(refs: Sequence[str]) -> list[str]:
    lines: list[str] = []
    facts = [r for r in refs if C.ref_kind(r) == "fact"]
    risks = [r for r in refs if C.ref_kind(r) == "risk"]
    checks = [r for r in refs if C.ref_kind(r) == "checklist"]
    sections = [r for r in refs if C.ref_kind(r) == "section"]

    def anchor(ref: str) -> str:
        return '<a id="ref-' + (re.sub(r"[^a-z0-9]", "", ref.lower()) or "ref") + '"></a>'

    if facts:
        lines += ["### Факты", "", "| Факт | Кратко | Где сказано | Источник |", "|---|---|---|---|"]
        for r in facts:
            fact = C.FACTS[r]
            url = f"[ссылка]({fact.url})" if fact.url else "первоисточника нет (вывод исследования)"
            lines.append(f"| {anchor(r)}{r} | {_cell(fact.text)} | {_cell(fact.where)} | {url} |")
        lines.append("")
    if risks:
        lines += ["### Риски", "", "| Риск | Кратко |", "|---|---|"]
        lines += [f"| {anchor(r)}{r} | {_cell(C.RISKS[r])} |" for r in risks]
        lines.append("")
    if checks:
        lines += [
            "### Пункты чек-листа «проверить вручную»",
            "",
            "Полный чек-лист с той же нумерацией — [раздел 9 чек-листа миграции]"
            "(migration_checklist.md#9-проверить-вручную).",
            "",
            "| Пункт | Что проверить |",
            "|---|---|",
        ]
        lines += [f"| {anchor(r)}{r} | {_cell(C.CHECKLIST[r])} |" for r in checks]
        lines.append("")
    if sections:
        lines += ["### Разделы исследования", ""]
        lines += [f"- {anchor(r)}{r} — {C.SECTIONS[r]}" for r in sections]
        lines.append("")
    return lines


def render_markdown(inv: Inventory, json_name: str = "docs/inventory.json") -> str:
    summaries = summarize(inv)
    out: list[str] = [
        "# Инвентаризация возможностей CODESYS: флагман и библиотека",
        "",
        "> Файл создаёт `tools/inventory.py` по настройкам `tools/inventory.toml`; вручную не правится.",
        "> Повторить — `python tools/inventory.py` (README, раздел «Инвентаризация возможностей CODESYS»).",
        f"> Данные для автоматизации — `{json_name}`.",
        "",
        f"Цель переноса: {C.TARGET}. Риск и ссылки (факты F, риски R, пункты чек-листа) — из: {C.RESEARCH}.",
        "Факты пересказаны кратко, первоисточники — в разделе [«Ссылки»](#ссылки); полная таблица фактов —",
        "в [приложении к таблице различий](differences.md#приложение-факты-и-источники).",
        "",
        "Счёт ведётся по разобранному тексту: комментарии и строки не учитываются. В ячейках с количеством —",
        "`src / tests`; «—» — у источника таких мест нет. Единицы: объект, член (метод или свойство), секция",
        "`VAR…END_VAR`, переменная, вхождение (место в тексте).",
        "",
        "## Источники",
        "",
        *_source_rows(inv),
        "",
        "## Объём кода",
        "",
        *_stats_rows(inv),
        "",
        "## Шкала риска",
        "",
        *[f"- **{risk}** — {text}." for risk, text in C.RISK_SCALE],
        "",
        "## Главные риски",
        "",
        "Возможности со средним и высоким риском, которые используются в коде, — по убыванию риска и числа мест.",
        "",
        *_top_risks(summaries, inv),
        "",
    ]
    for group, title in C.GROUPS:
        if group in ("task", "ident"):
            continue
        group_summaries = [s for s in summaries if s.feature.group == group]
        used = [s for s in group_summaries if s.total]
        unused = [s for s in group_summaries if not s.total]
        out += [f"## {title}", ""]
        if used:
            out += _feature_table(used, inv)
        else:
            out.append("В коде не найдено.")
        if unused:
            out += ["", "Не используются: " + "; ".join(s.feature.title for s in unused) + "."]
        out.append("")
    task_summary = next(s for s in summaries if s.feature.id == "task.config")
    out += [
        "## Задачи",
        "",
        f"Риск: {task_summary.feature.risk} ({_refs(task_summary.feature.refs)}). {task_summary.feature.action}.",
        "",
        *_task_rows(inv),
        "",
        "## Идентификаторы",
        "",
        "Имена, которые CODESYS допускает, а другие инструменты МЭК считают ключевыми словами. Для Astra.IDE",
        f"(база CODESYS 3.5.17, {_ref_link('F01')}) они не мешают; важны для RuSTy и iec_checker в CI и для",
        "следующих сред (MasterSCADA 4D, «Полигон» — их списки ключевых слов здесь не проверялись).",
        "",
        *_identifier_rows(inv),
        "",
    ]
    vendor = next(s for s in summaries if s.feature.id == "ident.vendor_prefix")
    out.append(
        "Имена объектов с префиксом `Ps` (занят библиотеками РегЛаб, "
        + _refs(vendor.feature.refs)
        + "): "
        + (_objects_cell(vendor, inv) if vendor.total else "нет")
        + "."
    )
    out += [
        "",
        "Списки ключевых слов:",
        "",
        *[f"- {title}: [{src[0]}]({src[1]})" for _fid, title, _w, src in C.RESERVED_SETS],
        "",
        "## Не покрыто исследованием",
        "",
        "Найдены в коде, но фактов о них в исследовании Astra.IDE нет — проверяются по чек-листу «проверить вручную».",
        "",
        *_unresearched(summaries),
        "",
        "## Где именно",
        "",
        f"Файлы и строки по каждой возможности (не больше {MAX_FILES_IN_MD} файлов; остальное — в `{json_name}`).",
        "",
        *_where(summaries, inv, json_name),
        "## Ссылки",
        "",
        *_references(_used_refs(summaries, inv)),
    ]
    return L.normalize_text("\n".join(out))


# ---------------------------------------------------------------------------
# JSON
# ---------------------------------------------------------------------------


def _places(files: Sequence[tuple[str, str, str, list[int]]]) -> dict[str, dict[str, list[int]]]:
    """Где встречается возможность: источник -> файл (путь от корня источника) -> строки."""
    places: dict[str, dict[str, list[int]]] = {}
    for src, path, _obj, lines in files:
        places.setdefault(src, {})[path] = lines
    return places


def build_json(inv: Inventory) -> dict[str, Any]:
    summaries = summarize(inv)
    sources = []
    for data in inv.sources:
        snap = data.snap
        sources.append(
            {
                "id": data.spec.id,
                "title": data.spec.title,
                "path": snap.display_path,
                "rev": snap.rev or WORKTREE,
                "commit": snap.commit,
                "commit_date": snap.commit_date,
                "dirty": snap.dirty,
                "dirty_worktree": snap.dirty_worktree,
                "dirs": list(data.spec.dirs),
                "objects": len(data.objects),
                "skipped_baseline": sorted(data.skipped, key=lambda n: (n.lower(), n)),
                "skipped_tasks": data.skipped_tasks,
                "layout_issues": [i.format() for i in data.issues],
                "stats": {k: v.to_json() for k, v in source_stats(data).items()},
            }
        )
    features = []
    for s in summaries:
        f = s.feature
        features.append(
            {
                "id": f.id,
                "group": f.group,
                "title": f.title,
                "unit": f.unit,
                "risk": f.risk,
                "refs": list(f.refs),
                "action": f.action,
                "total": s.total,
                "counts": s.counts,
                "objects": s.objects,
                "details": dict(sorted(s.details.items())),
                "places": _places(s.files),
            }
        )
    refs = _used_refs(summaries, inv)
    return {
        "schema": SCHEMA,
        "target": C.TARGET,
        "research": C.RESEARCH,
        "risk_scale": [{"risk": r, "meaning": t} for r, t in C.RISK_SCALE],
        "sources": sources,
        "features": features,
        "tasks": [
            {
                "source": t.source,
                "mode": t.mode,
                "name": t.name,
                "interval_ms": t.interval_ms,
                "priority": t.priority,
                "pous": t.pous,
                "remark": t.remark,
            }
            for t in inv.tasks
        ],
        "libraries": [
            {
                "source": lib.source,
                "key": lib.key,
                "label": lib.label,
                "version": lib.version,
                "namespace": lib.namespace,
                "modes": lib.modes,
                "feature": lib.feature or None,
            }
            for lib in inv.libraries
        ],
        "references": {
            "facts": {
                r: {"text": C.FACTS[r].text, "where": C.FACTS[r].where, "url": C.FACTS[r].url}
                for r in refs
                if C.ref_kind(r) == "fact"
            },
            "risks": {r: C.RISKS[r] for r in refs if C.ref_kind(r) == "risk"},
            "checklist": {r: C.CHECKLIST[r] for r in refs if C.ref_kind(r) == "checklist"},
            "sections": {r: C.SECTIONS[r] for r in refs if C.ref_kind(r) == "section"},
        },
    }


def _is_leaf(value: Any) -> bool:
    if isinstance(value, (str, int, float, bool)) or value is None:
        return True
    if isinstance(value, list):
        return all(isinstance(v, (str, int, float, bool)) or v is None for v in value)
    return False


def json_text(value: Any, indent: int = 0) -> str:
    """JSON с отступами, но «листовые» значения и короткие объекты — в одну строку (короткий дифф)."""
    pad = "  " * indent
    inner = "  " * (indent + 1)
    if _is_leaf(value):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, dict):
        if not value:
            return "{}"
        if all(_is_leaf(v) for v in value.values()):
            flat = json.dumps(value, ensure_ascii=False)
            if len(flat) + len(pad) <= 160:
                return flat
        items = [f"{inner}{json.dumps(k, ensure_ascii=False)}: {json_text(v, indent + 1)}" for k, v in value.items()]
        return "{\n" + ",\n".join(items) + "\n" + pad + "}"
    if isinstance(value, list):
        if not value:
            return "[]"
        items = [inner + json_text(v, indent + 1) for v in value]
        return "[\n" + ",\n".join(items) + "\n" + pad + "]"
    raise TypeError(f"не сериализуется в JSON: {type(value).__name__}")


# ---------------------------------------------------------------------------
# Командная строка
# ---------------------------------------------------------------------------


def run(
    config: Config,
    base_dir: str,
    use_baseline: bool = True,
    allow_missing: bool = False,
    err: Any = None,
) -> Inventory:
    stream = err if err is not None else sys.stderr
    with ExitStack() as stack:
        sources: list[SourceData] = []
        for spec in config.sources:
            try:
                sources.append(load_source(spec, config, base_dir, stack, use_baseline))
            except InventoryError as exc:
                if not allow_missing:
                    raise
                print(f"inventory: источник {spec.id} пропущен: {exc}", file=stream)
        for data in sources:
            for issue in data.issues:
                print(f"inventory: {data.spec.id}: {issue.format()}", file=stream)
        return analyze(sources)


def configure_output() -> None:
    """Вывод в UTF-8 и при перенаправлении в файл (Windows по умолчанию — cp1251)."""
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="replace")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="inventory.py",
        description="Инвентаризация возможностей CODESYS в исходниках ST для переноса на Astra.IDE",
    )
    parser.add_argument("--root", default=REPO_ROOT, help="корень репозитория (от него — пути настроек)")
    parser.add_argument("--config", default=None, help=f"файл настроек (по умолчанию {DEFAULT_CONFIG})")
    parser.add_argument(
        "--source",
        action="append",
        default=[],
        metavar="ID=ПУТЬ[@РЕВИЗИЯ]",
        help="заменить путь и ревизию источника или базовой линии; ревизия worktree — рабочее дерево",
    )
    parser.add_argument("--md", default=None, help="куда писать Markdown (по умолчанию — из настроек)")
    parser.add_argument("--json", default=None, help="куда писать JSON (по умолчанию — из настроек)")
    parser.add_argument("--no-baseline", action="store_true", help="не пропускать объекты базовой линии")
    parser.add_argument("--allow-missing", action="store_true", help="пропускать ненайденные источники")
    parser.add_argument("--check", action="store_true", help="не писать, а сравнить с существующими файлами")
    parser.add_argument("-q", "--quiet", action="store_true", help="без итоговой строки")
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    configure_output()
    args = build_parser().parse_args(argv)
    root = os.path.abspath(args.root)
    try:
        config = load_config(os.path.join(root, args.config or DEFAULT_CONFIG))
        for spec in args.source:
            config = override_source(config, spec)
        inv = run(config, root, not args.no_baseline, args.allow_missing)
    except InventoryError as exc:
        print(f"inventory: ошибка: {exc}", file=sys.stderr)
        return 1
    md_path = os.path.join(root, args.md or config.markdown)
    json_path = os.path.join(root, args.json or config.json)
    json_name = display_path(json_path, root)
    outputs = {
        md_path: render_markdown(inv, json_name),
        json_path: json_text(build_json(inv)) + "\n",
    }
    if args.check:
        stale = [p for p, text in outputs.items() if not os.path.isfile(p) or L.read_text(p) != text]
        for path in stale:
            print(
                f"inventory: устарел {display_path(path, root)} — запустите python tools/inventory.py", file=sys.stderr
            )
        return 1 if stale else 0
    for path, text in outputs.items():
        L.write_text(path, text)
    if not args.quiet:
        used = sum(1 for s in summarize(inv) if s.total)
        print(
            f"inventory: источников {len(inv.sources)}, вхождений {len(inv.occurrences)}, возможностей {used}; "
            f"записано {display_path(md_path, root)}, {display_path(json_path, root)}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
