"""Тесты tools/upstream_delta.py: дельта оригинала на временном репозитории git.

Оригинал — репозиторий с деревом src из пяти файлов; снимок и перенос — его копии, в переносе часть
файлов правлена. Второй коммит оригинала меняет файлы так, чтобы получились все действия: заменить,
слить, конфликт, скопировать, удалить.
"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest

import upstream_delta as UD

# Плейсхолдер портфолио собран из кодов символов: скрипт подстановки не должен его заменить
PLACEHOLDER = chr(60) + "ИМЯ ФАМИЛИЯ" + chr(62)

BASE = {
    "A.st": "a1\na2\na3\n",
    "B.st": "b1\nb2\nb3\nb4\nb5\nb6\nb7\n",
    "C.st": "c1\nc2\nc3\n",
    "E.st": "e1\n",
    "H.st": f"// Автор: {PLACEHOLDER}\nh1\n",
}


def _git(repo: Path, *args: str) -> str:
    cmd = ["git", "-C", str(repo), "-c", "user.name=t", "-c", "user.email=t@example.invalid", *args]
    return subprocess.run(cmd, check=True, capture_output=True, text=True).stdout.strip()


def _write(root: Path, files: dict[str, str]) -> None:
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode("utf-8"))


@pytest.fixture
def setup(tmp_path: Path) -> tuple[Path, Path, str]:
    """(корень переноса, репозиторий оригинала, базовый коммит)."""
    if shutil.which("git") is None:
        pytest.skip("нет git")
    upstream = tmp_path / "orig"
    upstream.mkdir()
    _git(upstream, "init", "-q", "-b", "main")
    _write(upstream, {f"src/{k}": v for k, v in BASE.items()} | {"docs/x.md": "x\n"})
    _git(upstream, "add", "-A")
    _git(upstream, "commit", "-q", "-m", "base")
    base = _git(upstream, "rev-parse", "HEAD")
    root = tmp_path / "port"
    snapshot = {k: v.replace(PLACEHOLDER, "kr0nsch") for k, v in BASE.items()}
    _write(root / "upstream" / "orig" / "src", snapshot)
    port = dict(snapshot)
    port["B.st"] = "// PORT: [oop] проверить в Astra.IDE — THIS^ (C2)\nb1\nb2\nb3\nb4\nb5\nb6\nb7\n"
    port["C.st"] = "c1\nc2 // PORT: [types] правка\nc3\n"
    _write(root / "targets" / "src", port)
    sources = {
        "sources": [
            {
                "id": "orig",
                "repo": str(upstream),
                "ref": "main",
                "commit": base,
                "date": "",
                "subdir": "src",
                "snapshot": "upstream/orig/src",
                "target": "targets/src",
                "exclude": [],
                "substitutions": {PLACEHOLDER: "kr0nsch"},
            }
        ]
    }
    (root / "upstream" / "SOURCES.json").write_text(json.dumps(sources, ensure_ascii=False), encoding="utf-8")
    # Второй коммит: A — правка (в переносе без правок), B — правка вдали от маркера, C — правка той же
    # строки, что в переносе, D — новый файл, E — удалён, H — только плейсхолдер (дельты нет)
    _write(
        upstream,
        {
            "src/A.st": "a1\nA2\na3\n",
            "src/B.st": "b1\nb2\nb3\nb4\nb5\nb6\nB7\n",
            "src/C.st": "c1\nC2\nc3\n",
            "src/D.st": "d1\n",
        },
    )
    (upstream / "src" / "E.st").unlink()
    _git(upstream, "add", "-A")
    _git(upstream, "commit", "-q", "-m", "fixes")
    return root, upstream, base


def _sources_path(root: Path) -> str:
    return str(root / "upstream" / "SOURCES.json")


def test_delta_classifies_every_case(setup: tuple[Path, Path, str]) -> None:
    root, upstream, _ = setup
    _, sources = UD.load_sources(_sources_path(root))
    delta = UD.build_delta(sources[0], str(upstream), "main", str(root))
    actions = {item.path: item.action for item in delta.items}
    assert actions == {
        "A.st": UD.ACT_REPLACE,
        "B.st": UD.ACT_MERGE,
        "C.st": UD.ACT_CONFLICT,
        "D.st": UD.ACT_COPY,
        "E.st": UD.ACT_DELETE,
    }
    merged = next(i for i in delta.items if i.path == "B.st").merged
    assert merged is not None and merged.decode().startswith("// PORT: [oop]") and b"B7" in merged
    text = UD.render_md(delta)
    assert "| `C.st` | изменён | с правками | 1 | **конфликт** |" in text
    assert "заменить — 1, слить — 1, скопировать — 1, удалить — 1, конфликт — 1" in text


def test_apply_like_git_merge(setup: tuple[Path, Path, str]) -> None:
    root, upstream, base = setup
    args = ["orig", "--sources", _sources_path(root), "--apply"]
    assert UD.main(args, root=str(root)) == 1  # конфликт в C
    target = root / "targets" / "src"
    assert (target / "A.st").read_text(encoding="utf-8") == "a1\nA2\na3\n"
    assert (target / "D.st").exists() and not (target / "E.st").exists()
    assert "B7" in (target / "B.st").read_text(encoding="utf-8")
    conflict = (target / "C.st").read_text(encoding="utf-8")
    assert conflict.startswith("c1\n<<<<<<< перенос\nc2 // PORT: [types] правка\n")
    assert ">>>>>>> стало" in conflict
    raw = (root / "upstream" / "SOURCES.json").read_text(encoding="utf-8")
    assert "<" not in raw and "\\u003c" in raw  # плейсхолдер записан кодами
    head = _git(upstream, "rev-parse", "HEAD")
    assert json.loads(raw)["sources"][0]["commit"] == head != base
    snap = root / "upstream" / "orig" / "src"
    assert sorted(p.name for p in snap.iterdir()) == ["A.st", "B.st", "C.st", "D.st", "H.st"]
    assert (snap / "H.st").read_text(encoding="utf-8").startswith("// Автор: kr0nsch")
    # Пока конфликт не разобран, следующий --apply отказывается
    assert UD.main(args, root=str(root)) == 2
    (target / "C.st").write_text("c1\nC2 // PORT: [types] правка\nc3\n", encoding="utf-8")
    # Дельты больше нет; снимок совпадает с коммитом
    assert UD.main(["orig", "--sources", _sources_path(root)], root=str(root)) == 0
    assert UD.main(["orig", "--sources", _sources_path(root), "--verify"], root=str(root)) == 0
    assert UD.main(args, root=str(root)) == 0


def test_verify_reports_snapshot_drift(setup: tuple[Path, Path, str], capsys: pytest.CaptureFixture[str]) -> None:
    root, _, _ = setup
    (root / "upstream" / "orig" / "src" / "A.st").write_text("changed\n", encoding="utf-8")
    assert UD.main(["--sources", _sources_path(root), "--verify"], root=str(root)) == 1
    assert "upstream/orig/src/A.st: отличается" in capsys.readouterr().out


def test_errors(setup: tuple[Path, Path, str], capsys: pytest.CaptureFixture[str]) -> None:
    root, _, _ = setup
    assert UD.main(["nope", "--sources", _sources_path(root)], root=str(root)) == 2
    assert UD.main(["orig", "--sources", _sources_path(root), "--to", "no-such-rev"], root=str(root)) == 2
    assert UD.main(["orig", "--sources", _sources_path(root), "--repo", str(root / "none")], root=str(root)) == 2
    assert UD.main(["--sources", str(root / "missing.json")], root=str(root)) == 2
    assert "upstream_delta:" in capsys.readouterr().err


def test_excluded_paths_are_ignored(tmp_path: Path) -> None:
    assert UD._excluded("POUs/PRG_Main/PRG_Main.decl.st", ["POUs/PRG_Main/"])
    assert UD._excluded("POUs/PRG_Main", ["POUs/PRG_Main/"])
    assert not UD._excluded("POUs/PRG_MainX/a.st", ["POUs/PRG_Main/"])


def test_repository_sources_file_is_consistent() -> None:
    """upstream/SOURCES.json репозитория: снимки и деревья переноса существуют, коммиты полные."""
    repo = Path(UD.REPO_ROOT)
    _, sources = UD.load_sources(UD.DEFAULT_SOURCES)
    assert [s.id for s in sources] == ["kns-pump-station", "plc-process-lib"]
    for source in sources:
        assert len(source.get("commit")) == 40
        assert (repo / source.get("snapshot")).is_dir()
        assert (repo / source.get("target")).is_dir()
    raw = Path(UD.DEFAULT_SOURCES).read_text(encoding="utf-8")
    assert PLACEHOLDER not in raw  # ключи подстановки записаны кодами <…>
