"""Тесты tools/port_checks.py: места конструкций, маркеры проверки, --fix, --resolve, --fail."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

import port_checks as PC

FB_DECL = """// Назначение: тест.
// Автор:      t
// Версия:     0.1.0
// Документ:   docs/x.md
FUNCTION_BLOCK FB_B EXTENDS FB_A
VAR_INPUT
    x : BOOL;   // SUPER^ в комментарии не считается
END_VAR
"""
FB_IMPL = """s := 'THIS^ в строке';
SUPER^.Run();
    lt := LTIME() + LTIME#1S;
"""
METHOD = """// Описание метода
METHOD PROTECTED Run : BOOL
VAR_IN_OUT CONSTANT
    st : INT;
END_VAR
"""
ENUM = """{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_X :
(
    A := 1
) INT;
END_TYPE
"""
GVL_MIXED = """VAR_GLOBAL CONSTANT
    N : INT := 1;
END_VAR
VAR_GLOBAL
    x : INT;
END_VAR
"""


def _tree(root: Path) -> Path:
    src = root / "src"
    files = {
        "POUs/FB_B/FB_B.decl.st": FB_DECL,
        "POUs/FB_B/FB_B.impl.st": FB_IMPL,
        "POUs/FB_B/Run.method.decl.st": METHOD,
        "POUs/FB_B/Run.method.impl.st": "Run := TRUE;\n",
        "DUTs/E_X.dut.st": ENUM,
        "GVLs/GVL_M.gvl.st": GVL_MIXED,
    }
    for rel, text in files.items():
        path = src / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode("utf-8"))
    return src


def _decisions(root: Path) -> str:
    path = root / "port_checks.json"
    path.write_text(json.dumps({"trees": ["src"], "verified": {}, "failed": {}}), encoding="utf-8")
    return str(path)


def _report(root: Path) -> PC.Report:
    return PC.check_trees(["src"], PC.load_decisions(str(root / "port_checks.json")), base=str(root))


def test_places_ignore_comments_and_strings(tmp_path: Path) -> None:
    _tree(tmp_path)
    _decisions(tmp_path)
    report = _report(tmp_path)
    found = sorted((p.path.split("src/", 1)[1], p.line, item) for p in report.places() for _, item in p.groups())
    assert found == [
        ("DUTs/E_X.dut.st", 2, "C5"),
        ("DUTs/E_X.dut.st", 6, "C7"),
        ("GVLs/GVL_M.gvl.st", 4, "B3"),
        ("POUs/FB_B/FB_B.decl.st", 5, "C1"),
        ("POUs/FB_B/FB_B.impl.st", 2, "C1"),
        ("POUs/FB_B/FB_B.impl.st", 3, "C11"),
        ("POUs/FB_B/FB_B.impl.st", 3, "C11"),
        ("POUs/FB_B/Run.method.decl.st", 2, "C3"),
        ("POUs/FB_B/Run.method.decl.st", 3, "C13"),
    ]
    assert all(f.kind == PC.KIND_MISSING for f in report.findings)
    assert len(report.findings) == 9


def test_fix_inserts_markers_with_indent_and_is_idempotent(tmp_path: Path) -> None:
    src = _tree(tmp_path)
    config = _decisions(tmp_path)
    assert PC.main(["--config", config, "--tree", str(src), "--fix", "-q"]) == 0
    impl = (src / "POUs/FB_B/FB_B.impl.st").read_text(encoding="utf-8")
    assert impl == (
        "s := 'THIS^ в строке';\n"
        "// PORT: [oop] проверить в Astra.IDE — вызов базовой реализации SUPER^ (C1)\n"
        "SUPER^.Run();\n"
        "    // PORT: [time] проверить в Astra.IDE — оператор LTIME(), монотонность (C11)\n"
        "    // PORT: [types] проверить в Astra.IDE — литералы и преобразования LTIME (C11)\n"
        "    lt := LTIME() + LTIME#1S;\n"
    )
    decl = (src / "POUs/FB_B/Run.method.decl.st").read_text(encoding="utf-8")
    assert "// PORT: [oop] проверить в Astra.IDE — спецификатор доступа PROTECTED (C3)\nMETHOD PROTECTED" in decl
    report = PC.check_trees([str(src)], PC.load_decisions(config), base=str(tmp_path))
    assert report.findings == []
    before = {p: p.read_bytes() for p in src.rglob("*.st")}
    assert PC.main(["--config", config, "--tree", str(src), "--fix", "--strict", "-q"]) == 0
    assert before == {p: p.read_bytes() for p in src.rglob("*.st")}


def test_resolve_removes_markers_of_verified_item(tmp_path: Path) -> None:
    src = _tree(tmp_path)
    config = _decisions(tmp_path)
    PC.main(["--config", config, "--tree", str(src), "--fix", "-q"])
    note = "2026-10-25, Astra.IDE 1.7.2.2: собирается"
    assert PC.main(["--config", config, "--tree", str(src), "--resolve", "C1", "--note", note, "-q"]) == 0
    assert "(C1)" not in (src / "POUs/FB_B/FB_B.decl.st").read_text(encoding="utf-8")
    assert "(C1)" not in (src / "POUs/FB_B/FB_B.impl.st").read_text(encoding="utf-8")
    assert "(C11)" in (src / "POUs/FB_B/FB_B.impl.st").read_text(encoding="utf-8")
    data = json.loads(Path(config).read_text(encoding="utf-8"))
    assert data["verified"] == {"C1": note}
    assert PC.main(["--config", config, "--tree", str(src), "--strict", "-q"]) == 0


def test_fail_makes_every_place_an_error(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    src = _tree(tmp_path)
    config = _decisions(tmp_path)
    PC.main(["--config", config, "--tree", str(src), "--fix", "-q"])
    assert PC.main(["--config", config, "--tree", str(src), "--fail", "C3", "--note", "BUILD_ERRORS 1.2"]) == 0
    assert PC.main(["--config", config, "--tree", str(src), "--strict", "-q"]) == 1
    assert "конструкция проваленного пункта: [oop] C3" in capsys.readouterr().err


def test_stale_rule_marker_and_manual_marker(tmp_path: Path) -> None:
    src = _tree(tmp_path)
    _decisions(tmp_path)
    impl = src / "POUs/FB_B/Run.method.impl.st"
    impl.write_text(
        "// PORT: [oop] проверить в Astra.IDE — вызов базовой реализации SUPER^ (C1)\n"
        "// PORT: [comm] проверить в Astra.IDE — статус канала (E2)\n"
        "Run := TRUE;\n",
        encoding="utf-8",
    )
    report = _report(tmp_path)
    extra = [(f.line, f.item) for f in report.findings if f.kind == PC.KIND_EXTRA]
    assert extra == [(1, "C1")]  # SUPER^ рядом нет; ручной маркер E2 не проверяется
    PC.main(["--config", str(tmp_path / "port_checks.json"), "--tree", str(src), "--fix", "-q"])
    assert impl.read_text(encoding="utf-8").startswith("// PORT: [comm]")


@pytest.mark.parametrize(
    ("comment", "parsed"),
    [
        ("// PORT: [oop] проверить в Astra.IDE — THIS^ (C2)", ("oop", ("C2",))),
        ("// PORT: [comm] проверить в Astra.IDE — тип [F58] (E2)", ("comm", ("E2",))),
        ("// PORT: [hmi] проверить в Astra.IDE — экраны (F1, F3)", ("hmi", ("F1", "F3"))),
        ("// PORT: [oop] композиция вместо EXTENDS", None),
        ("// просто комментарий", None),
    ],
)
def test_parse_check_marker(comment: str, parsed: tuple[str, tuple[str, ...]] | None) -> None:
    result = PC.parse_check_marker(comment)
    assert (None if result is None else (result[0], result[2])) == parsed


def test_bad_decisions_file(tmp_path: Path) -> None:
    bad = tmp_path / "bad.json"
    bad.write_text(json.dumps({"verified": {"C1": "x"}, "failed": {"C1": "y"}}), encoding="utf-8")
    assert PC.main(["--config", str(bad), "--tree", str(tmp_path)]) == 2
    assert PC.main(["--config", str(tmp_path / "none.json"), "--tree", str(tmp_path / "no-dir")]) == 2
    assert PC.main(["--config", str(tmp_path / "none.json"), "--tree", str(tmp_path), "--resolve", "Z9"]) == 2


def test_repository_trees_are_fully_marked() -> None:
    """targets/astra: у каждой конструкции из правил — маркер проверки, лишних маркеров нет."""
    decisions = PC.load_decisions(PC.DEFAULT_CONFIG)
    report = PC.check_trees(decisions.trees, decisions)
    assert report.findings == []
    assert len(report.places()) > 0
