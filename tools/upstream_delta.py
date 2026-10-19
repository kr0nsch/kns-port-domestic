#!/usr/bin/env python3
"""Дельта оригинала для переноса: что изменилось в флагмане или библиотеке и что делать с перенесёнными файлами.

Перенос сделан с зафиксированных коммитов (upstream/SOURCES.json), их деревья src лежат снимками в
upstream/<id>/src. Оригинал продолжает получать исправления; чтобы перенести их в targets/astra/,
инструмент сравнивает снимок (было) с деревом нового коммита (стало) и для каждого изменённого файла
смотрит перенесённую копию:

- копия совпадает со снимком (в переносе файл не правили) — заменить новым;
- копию правили (маркеры PORT, правки) — трёхстороннее слияние `git merge-file`: без конфликтов —
  правки переноса сохраняются, с конфликтами — разобрать вручную;
- файл добавлен в оригинале — скопировать; удалён — удалить, если в переносе его не правили.

Без --apply только печатает таблицу (Markdown, можно сохранить --md). С --apply — как git merge:
чистые результаты записываются, файлы с конфликтами — с маркерами конфликта git (<<<<<<< перенос,
||||||| было, ======= , >>>>>>> стало), а снимок и коммит в upstream/SOURCES.json переходят на новую
версию. Пока в переносе остаются маркеры конфликта, следующий --apply отказывается работать.
После --apply: разобрать конфликты и ручные пункты, затем tools/port_checks.py --fix (новые места для
проверки) и tools/port_metrics.py --strict.

Коды выхода: 0 — успех (нет конфликтов и ручных пунктов); 1 — есть конфликты или ручные пункты, или
--verify нашёл расхождения; 2 — неверные аргументы, нет репозитория или ревизии, в переносе остались
маркеры конфликта.
"""

from __future__ import annotations

import argparse
import datetime as dt
import io
import json
import os
import subprocess
import sys
import tarfile
import tempfile
from collections.abc import Sequence
from dataclasses import dataclass, field

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(TOOLS_DIR)
DEFAULT_SOURCES = os.path.join(REPO_ROOT, "upstream", "SOURCES.json")

# Изменение в оригинале
CH_ADDED = "добавлен"
CH_DELETED = "удалён"
CH_MODIFIED = "изменён"

# Действие с перенесённой копией
ACT_COPY = "скопировать"
ACT_REPLACE = "заменить"
ACT_MERGE = "слить"
ACT_DELETE = "удалить"
ACT_NONE = "ничего"
ACT_CONFLICT = "конфликт"
ACT_MANUAL = "вручную"
MANUAL_ACTIONS = (ACT_CONFLICT, ACT_MANUAL)


class UsageError(Exception):
    """Неверные аргументы, нет репозитория или ревизии (код выхода 2)."""


@dataclass
class Source:
    """Запись upstream/SOURCES.json."""

    data: dict[str, object]

    def get(self, key: str) -> str:
        value = self.data.get(key, "")
        return str(value) if value is not None else ""

    @property
    def id(self) -> str:
        return self.get("id")

    @property
    def exclude(self) -> list[str]:
        value = self.data.get("exclude", [])
        return [str(v) for v in value] if isinstance(value, list) else []

    @property
    def substitutions(self) -> dict[str, str]:
        value = self.data.get("substitutions", {})
        return {str(k): str(v) for k, v in value.items()} if isinstance(value, dict) else {}


@dataclass
class Item:
    """Файл, изменённый в оригинале, и что делать с его копией в переносе."""

    path: str
    change: str
    in_port: str
    action: str
    markers: int = 0
    note: str = ""
    new: bytes | None = None
    merged: bytes | None = None


@dataclass
class Delta:
    """Дельта одного источника."""

    source: Source
    base_commit: str
    new_commit: str
    new_ref: str
    new_date: str
    items: list[Item] = field(default_factory=list)
    new_tree: dict[str, bytes] = field(default_factory=dict)

    @property
    def manual(self) -> list[Item]:
        return [i for i in self.items if i.action in MANUAL_ACTIONS]


# ---------------------------------------------------------------------------
# Файлы и git
# ---------------------------------------------------------------------------


def load_sources(path: str) -> tuple[dict[str, object], list[Source]]:
    try:
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        raise UsageError(f"{path}: {exc}") from exc
    sources = data.get("sources") if isinstance(data, dict) else None
    if not isinstance(sources, list):
        raise UsageError(f"{path}: нет списка sources")
    return data, [Source(s) for s in sources if isinstance(s, dict)]


def save_sources(path: str, data: dict[str, object]) -> None:
    """JSON с угловыми скобками кодами \\u003c и \\u003e: плейсхолдеры портфолио не заменит скрипт подстановки."""
    text = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    text = text.replace("<", "\\u003c").replace(">", "\\u003e")
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


def _git(repo: str, *args: str) -> bytes:
    try:
        proc = subprocess.run(["git", "-C", repo, *args], capture_output=True, check=False)
    except OSError as exc:
        raise UsageError(f"git недоступен: {exc}") from exc
    if proc.returncode != 0:
        message = proc.stderr.decode("utf-8", "replace").strip()
        raise UsageError(f"git {' '.join(args)}: {message}")
    return proc.stdout


def resolve(repo: str, rev: str) -> tuple[str, str]:
    """Ревизия → (полный хеш коммита, дата коммита ISO)."""
    commit = _git(repo, "rev-parse", "--verify", "--quiet", f"{rev}^{{commit}}").decode().strip()
    date = _git(repo, "log", "-1", "--format=%cI", commit).decode().strip()
    return commit, date


def _excluded(rel: str, exclude: Sequence[str]) -> bool:
    return any(rel == p.rstrip("/") or rel.startswith(p if p.endswith("/") else p + "/") for p in exclude)


def substitute(data: bytes, substitutions: dict[str, str]) -> bytes:
    if not substitutions:
        return data
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError:
        return data
    for key, value in substitutions.items():
        text = text.replace(key, value)
    return text.encode("utf-8")


def archive_tree(repo: str, commit: str, subdir: str, source: Source) -> dict[str, bytes]:
    """Файлы subdir коммита: путь от subdir → содержимое с подстановкой substitutions."""
    # Содержимое как в репозитории: без перевода строк в CRLF (core.autocrlf в Windows)
    raw = _git(repo, "-c", "core.autocrlf=false", "archive", "--format=tar", commit, subdir)
    tree: dict[str, bytes] = {}
    prefix = subdir.strip("/") + "/"
    with tarfile.open(fileobj=io.BytesIO(raw)) as tar:
        for member in tar.getmembers():
            if not member.isfile() or not member.name.startswith(prefix):
                continue
            rel = member.name[len(prefix) :]
            if _excluded(rel, source.exclude):
                continue
            handle = tar.extractfile(member)
            if handle is not None:
                tree[rel] = substitute(handle.read(), source.substitutions)
    return tree


def read_tree(root: str, exclude: Sequence[str] = ()) -> dict[str, bytes]:
    tree: dict[str, bytes] = {}
    if not os.path.isdir(root):
        return tree
    for dirpath, _dirs, files in os.walk(root):
        for name in files:
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root).replace(os.sep, "/")
            if _excluded(rel, exclude):
                continue
            with open(full, "rb") as fh:
                tree[rel] = fh.read()
    return tree


def count_markers(data: bytes | None) -> int:
    if not data:
        return 0
    return data.decode("utf-8", "replace").count("// PORT:")


def merge3(ours: bytes, base: bytes, theirs: bytes) -> tuple[bytes, int]:
    """Трёхстороннее слияние git merge-file: (результат, число конфликтов)."""
    with tempfile.TemporaryDirectory() as tmp:
        paths = []
        for name, data in (("port", ours), ("base", base), ("new", theirs)):
            path = os.path.join(tmp, name)
            with open(path, "wb") as fh:
                fh.write(data)
            paths.append(path)
        cmd = ["git", "merge-file", "-p", "-L", "перенос", "-L", "было", "-L", "стало", *paths]
        proc = subprocess.run(cmd, capture_output=True, check=False)
    if proc.returncode < 0 or proc.returncode > 127:
        raise UsageError(f"git merge-file: {proc.stderr.decode('utf-8', 'replace').strip()}")
    return proc.stdout, proc.returncode


# ---------------------------------------------------------------------------
# Дельта
# ---------------------------------------------------------------------------


def build_delta(source: Source, repo: str, rev: str, root: str = REPO_ROOT) -> Delta:
    commit, date = resolve(repo, rev)
    old = read_tree(os.path.join(root, source.get("snapshot")), source.exclude)
    new = archive_tree(repo, commit, source.get("subdir") or "src", source)
    target_root = os.path.join(root, source.get("target"))
    delta = Delta(source, source.get("commit"), commit, rev, date, new_tree=new)
    for rel in sorted(set(old) | set(new)):
        before, after = old.get(rel), new.get(rel)
        if before == after:
            continue
        target_path = os.path.join(target_root, *rel.split("/"))
        port: bytes | None = None
        if os.path.isfile(target_path):
            with open(target_path, "rb") as fh:
                port = fh.read()
        delta.items.append(_classify(rel, before, after, port))
    return delta


def _classify(rel: str, before: bytes | None, after: bytes | None, port: bytes | None) -> Item:
    markers = count_markers(port)
    if before is None:
        assert after is not None
        if port is None:
            return Item(rel, CH_ADDED, "нет", ACT_COPY, markers, new=after)
        if port == after:
            return Item(rel, CH_ADDED, "уже такой же", ACT_NONE, markers, new=after)
        return Item(rel, CH_ADDED, "есть другой", ACT_MANUAL, markers, "файл с этим именем уже есть в переносе", after)
    if after is None:
        if port is None:
            return Item(rel, CH_DELETED, "нет", ACT_NONE, markers)
        if port == before:
            return Item(rel, CH_DELETED, "без правок", ACT_DELETE, markers)
        return Item(rel, CH_DELETED, "с правками", ACT_MANUAL, markers, "в переносе есть правки: удалить или оставить")
    if port is None:
        return Item(rel, CH_MODIFIED, "нет", ACT_MANUAL, markers, "файла нет в переносе (не перенесён?)", after)
    if port == before:
        return Item(rel, CH_MODIFIED, "без правок", ACT_REPLACE, markers, new=after)
    if port == after:
        return Item(rel, CH_MODIFIED, "уже такой же", ACT_NONE, markers, new=after)
    merged, conflicts = merge3(port, before, after)
    if conflicts:
        return Item(rel, CH_MODIFIED, "с правками", ACT_CONFLICT, markers, f"конфликтов: {conflicts}", after, merged)
    if merged == port:
        return Item(rel, CH_MODIFIED, "с правками", ACT_NONE, markers, "изменение уже есть в переносе", after, merged)
    return Item(rel, CH_MODIFIED, "с правками", ACT_MERGE, markers, "правки переноса сохранены", after, merged)


CONFLICT_START = "<<<<<<< перенос"


def unresolved_conflicts(source: Source, root: str = REPO_ROOT) -> list[str]:
    """Файлы переноса, где остались маркеры конфликта прошлого --apply."""
    target_root = os.path.join(root, source.get("target"))
    found = []
    for rel, data in read_tree(target_root).items():
        if any(line.startswith(CONFLICT_START) for line in data.decode("utf-8", "replace").splitlines()):
            found.append(f"{source.get('target')}/{rel}")
    return sorted(found)


def apply_delta(delta: Delta, root: str = REPO_ROOT, write_conflicts: bool = True) -> list[str]:
    """Записывает результаты в перенос (конфликты — с маркерами git). Возвращает изменённые пути."""
    target_root = os.path.join(root, delta.source.get("target"))
    changed: list[str] = []
    for item in delta.items:
        path = os.path.join(target_root, *item.path.split("/"))
        data: bytes | None = None
        if item.action in (ACT_COPY, ACT_REPLACE) or (item.action == ACT_CONFLICT and write_conflicts):
            data = item.new if item.action != ACT_CONFLICT else item.merged
        elif item.action == ACT_MERGE:
            data = item.merged
        elif item.action == ACT_DELETE:
            os.remove(path)
            changed.append(_rel(path, root))
            continue
        if data is None:
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(data)
        changed.append(_rel(path, root))
    return changed


def update_snapshot(delta: Delta, data: dict[str, object], sources_path: str, root: str = REPO_ROOT) -> None:
    """Снимок upstream/<id>/src — дерево нового коммита; коммит, ревизия и даты — в SOURCES.json."""
    snap_root = os.path.join(root, delta.source.get("snapshot"))
    current = read_tree(snap_root)
    for rel in current:
        if rel not in delta.new_tree and not _excluded(rel, delta.source.exclude):
            os.remove(os.path.join(snap_root, *rel.split("/")))
    for rel, content in delta.new_tree.items():
        path = os.path.join(snap_root, *rel.split("/"))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as fh:
            fh.write(content)
    _prune_empty_dirs(snap_root)
    delta.source.data.update(
        commit=delta.new_commit,
        ref=delta.new_ref,
        date=delta.new_date,
        snapshot_date=dt.date.today().isoformat(),
    )
    save_sources(sources_path, data)


def _prune_empty_dirs(root: str) -> None:
    for dirpath, dirs, files in os.walk(root, topdown=False):
        if dirpath != root and not dirs and not files:
            os.rmdir(dirpath)


def _rel(path: str, root: str) -> str:
    try:
        return os.path.relpath(path, root).replace(os.sep, "/")
    except ValueError:
        return path


def verify_snapshot(source: Source, repo: str, root: str = REPO_ROOT) -> list[str]:
    """Расхождения снимка с деревом записанного коммита (после подстановки)."""
    expected = archive_tree(repo, source.get("commit"), source.get("subdir") or "src", source)
    actual = read_tree(os.path.join(root, source.get("snapshot")), source.exclude)
    problems = []
    for rel in sorted(set(expected) | set(actual)):
        if expected.get(rel) != actual.get(rel):
            what = "нет в снимке" if rel not in actual else "лишний в снимке" if rel not in expected else "отличается"
            problems.append(f"{source.get('snapshot')}/{rel}: {what}")
    return problems


# ---------------------------------------------------------------------------
# Отчёт
# ---------------------------------------------------------------------------


def render_md(delta: Delta) -> str:
    s = delta.source
    lines = [
        f"## Дельта {s.id}: {delta.base_commit[:7]} → {delta.new_commit[:7]} ({delta.new_ref})",
        "",
        f"Снимок `{s.get('snapshot')}` (коммит `{delta.base_commit[:7]}`) → `{delta.new_ref}` = "
        f"`{delta.new_commit[:7]}` от {delta.new_date[:10]}; перенос — `{s.get('target')}`.",
        "",
    ]
    if not delta.items:
        return "\n".join([*lines, "Изменений в перенесённых каталогах нет.", ""])
    counts: dict[str, int] = {}
    for item in delta.items:
        counts[item.action] = counts.get(item.action, 0) + 1
    order = (ACT_REPLACE, ACT_MERGE, ACT_COPY, ACT_DELETE, ACT_NONE, ACT_CONFLICT, ACT_MANUAL)
    lines.append("Итог: " + ", ".join(f"{a} — {counts[a]}" for a in order if a in counts) + ".")
    lines += [
        "",
        "| Файл | В оригинале | Копия в переносе | Маркеров PORT | Действие | Примечание |",
        "|---|---|---|---|---|---|",
    ]
    for item in delta.items:
        action = f"**{item.action}**" if item.action in MANUAL_ACTIONS else item.action
        lines.append(f"| `{item.path}` | {item.change} | {item.in_port} | {item.markers} | {action} | {item.note} |")
    lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Командная строка
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="upstream_delta.py",
        description="Дельта оригинала (флагман, библиотека) для перенесённых файлов targets/astra/.",
    )
    parser.add_argument("source", nargs="*", help="id источника из upstream/SOURCES.json; по умолчанию — все")
    parser.add_argument("--to", help="новая ревизия оригинала (по умолчанию — ref из SOURCES.json)")
    parser.add_argument("--repo", help="рабочая копия оригинала (по умолчанию — repo или переменная repo_env)")
    parser.add_argument("--sources", default=DEFAULT_SOURCES, help="файл источников (upstream/SOURCES.json)")
    parser.add_argument(
        "--apply",
        action="store_true",
        help="записать результаты (конфликты — с маркерами git) и перевести снимок на новую версию",
    )
    parser.add_argument("--verify", action="store_true", help="сверить снимок с записанным коммитом и выйти")
    parser.add_argument("--md", help="сохранить таблицу в файл Markdown")
    return parser


def configure_output() -> None:
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is not None:
            reconfigure(encoding="utf-8", errors="replace")


def repo_path(source: Source, override: str | None, root: str = REPO_ROOT) -> str:
    env = source.get("repo_env")
    path = override or (os.environ.get(env, "") if env else "") or source.get("repo")
    if not path:
        raise UsageError(f"{source.id}: не задан репозиторий оригинала (--repo)")
    full = path if os.path.isabs(path) else os.path.join(root, path)
    if not os.path.isdir(full):
        raise UsageError(f"{source.id}: нет рабочей копии {path} (--repo или {source.get('repo_env')})")
    return full


def main(argv: Sequence[str] | None = None, root: str = REPO_ROOT) -> int:
    configure_output()
    parser = build_parser()
    try:
        args = parser.parse_args(argv)
    except SystemExit as exc:
        return 0 if exc.code in (0, None) else 2
    sources_path = os.path.abspath(args.sources)
    try:
        data, sources = load_sources(sources_path)
        known = {s.id: s for s in sources}
        unknown = [name for name in args.source if name not in known]
        if unknown:
            raise UsageError(f"нет источника: {', '.join(unknown)} (есть: {', '.join(known)})")
        selected = [known[name] for name in args.source] if args.source else sources
        if args.to and len(selected) != 1:
            raise UsageError("--to — только для одного источника")
        if args.verify:
            problems = []
            for source in selected:
                problems += verify_snapshot(source, repo_path(source, args.repo, root), root)
            for problem in problems:
                print(problem)
            print(f"upstream_delta: снимков {len(selected)}, расхождений {len(problems)}")
            return 1 if problems else 0
        reports = []
        manual = 0
        if args.apply:
            pending = [path for source in selected for path in unresolved_conflicts(source, root)]
            if pending:
                raise UsageError("в переносе не разобраны конфликты прошлого --apply: " + ", ".join(pending))
        for source in selected:
            repo = repo_path(source, args.repo, root)
            delta = build_delta(source, repo, args.to or source.get("ref") or "HEAD", root)
            reports.append(render_md(delta))
            manual += len(delta.manual)
            if args.apply:
                changed = apply_delta(delta, root)
                print(f"upstream_delta: {source.id}: записано файлов {len(changed)}", file=sys.stderr)
                if delta.new_commit != delta.base_commit or delta.items:
                    update_snapshot(delta, data, sources_path, root)
                    print(f"upstream_delta: {source.id}: снимок → {delta.new_commit[:7]}", file=sys.stderr)
                if delta.manual:
                    print(
                        f"upstream_delta: {source.id}: разобрать вручную {len(delta.manual)} "
                        "(конфликты — по маркерам <<<<<<< перенос … >>>>>>> стало)",
                        file=sys.stderr,
                    )
    except UsageError as exc:
        print(f"upstream_delta: {exc}", file=sys.stderr)
        return 2
    text = "\n".join(reports)
    print(text)
    if args.md:
        with open(args.md, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
    return 1 if manual else 0


if __name__ == "__main__":
    sys.exit(main())
