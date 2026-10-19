"""Тесты tools/inventory.py: поиск возможностей на малых фикстурах, настройки, чтение ревизий git, отчёты.

Фикстуры — tools/inventory_tests/fixtures/: lib (как библиотека: ООП, типы, конструкции, тесты
coUnit), app (как флагман: пространства имён, RETAIN/PERSISTENT, привязка AT, задачи в config.json)
и baseline (пример шаблона: совпадающие с ним объекты пропускаются). Ожидаемые числа посчитаны
вручную по файлам фикстур (комментарии у проверок).
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tomllib
from collections import Counter
from pathlib import Path
from typing import Any

import pytest

import inventory as INV
import inventory_catalog as C

HERE = Path(__file__).resolve().parent
FIXTURES = HERE / "fixtures"
REPO_ROOT = HERE.parent.parent

FIXTURE_CONFIG = """
[output]
markdown = "out/inventory.md"
json = "out/inventory.json"

[[source]]
id = "lib"
title = "Библиотека (фикстура)"
path = "lib"
rev = "worktree"

[[source]]
id = "app"
title = "Флагман (фикстура)"
path = "app"
rev = "worktree"
baseline = "base"

[baseline.base]
title = "пример шаблона (фикстура)"
path = "baseline"
rev = "worktree"
"""


def _config(text: str = FIXTURE_CONFIG, env: dict[str, str] | None = None) -> INV.Config:
    return INV.parse_config(tomllib.loads(text), env={} if env is None else env)


@pytest.fixture(scope="module")
def inv() -> INV.Inventory:
    return INV.run(_config(), str(FIXTURES))


def _occ(inv: INV.Inventory, fid: str, source: str | None = None) -> list[INV.Occurrence]:
    return [o for o in inv.occurrences if o.feature == fid and (source is None or o.source == source)]


def _total(inv: INV.Inventory, fid: str) -> int:
    return len(_occ(inv, fid))


def _details(inv: INV.Inventory, fid: str) -> Counter[str]:
    return Counter(o.detail for o in _occ(inv, fid))


def _summary(inv: INV.Inventory, fid: str) -> INV.FeatureSummary:
    return next(s for s in INV.summarize(inv) if s.feature.id == fid)


# ---------------------------------------------------------------------------
# Поиск возможностей
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("fid", "expected"),
    [
        ("oop.interface", 2),  # I_Base, I_Dev
        ("oop.interface_extends", 1),  # I_Dev EXTENDS I_Base
        ("oop.implements", 1),  # FB_Base IMPLEMENTS I_Dev
        ("oop.extends_fb", 2),  # FB_Child EXTENDS FB_Base, FB_Base_Test EXTENDS coUnit.FB_TestSuite
        ("oop.super", 2),  # SUPER^(...) в теле FB_Child, SUPER^.Reset() в FB_Child.Reset
        ("oop.this", 1),  # THIS^.Reset()
        ("oop.abstract", 2),  # FB_Base, FB_Base.OnTick
        ("oop.final", 2),  # FB_Child, FB_Child.Reset
        ("oop.method", 7),  # FB_Base: FB_init, OnTick, Reset; FB_Child: Helper, OnTick, Reset; ResetWorks
        ("oop.method_itf", 1),  # I_Base.Reset
        ("oop.access_public", 3),  # FB_Base.Reset, FB_Base.Value, FB_Child.Reset
        ("oop.access_default", 1),  # FB_Base.FB_init без спецификатора
        ("oop.access_private", 2),  # FB_Child.Helper, FB_Base_Test.ResetWorks
        ("oop.access_protected", 2),  # FB_Base.OnTick, FB_Child.OnTick
        ("oop.access_internal", 0),
        ("oop.property", 1),  # FB_Base.Value
        ("oop.property_get", 2),  # FB_Base.Value, I_Dev.Value
        ("oop.property_set", 1),  # FB_Base.Value
        ("oop.property_itf", 1),  # I_Dev.Value
        ("oop.fb_init", 1),
        ("oop.itf_var", 4),  # itfNext, itfA, itfB, PL.I_Motor во флагмане
        ("oop.queryinterface", 1),
    ],
)
def test_oop(inv: INV.Inventory, fid: str, expected: int) -> None:
    assert _total(inv, fid) == expected


def test_super_distinguishes_body_call_and_method(inv: INV.Inventory) -> None:
    assert _details(inv, "oop.super") == Counter({"SUPER^(…) — тело базы": 1, "SUPER^.метод": 1})


def test_modifiers_say_what_they_apply_to(inv: INV.Inventory) -> None:
    assert _details(inv, "oop.abstract") == Counter({"POU": 1, "метод": 1})
    assert _details(inv, "oop.access_public") == Counter({"метод": 2, "свойство": 1})


def test_interface_type_by_naming_rule_without_library_source(inv: INV.Inventory) -> None:
    # PL.I_Motor: библиотека PL не сканировалась, интерфейс узнаётся по правилу имён I_<Имя>
    assert _details(inv, "oop.itf_var") == Counter({"I_Base": 2, "I_Dev": 1, "PL.I_Motor": 1})


def test_comments_and_strings_are_not_counted(inv: INV.Inventory) -> None:
    # SUPER^ и LTIME() есть в комментарии заголовка FB_Base, __NEW — в строке sNote
    assert {o.obj for o in _occ(inv, "oop.super")} == {"FB_Child"}
    ltime = _occ(inv, "construct.ltime_op")
    assert [(o.path, o.line) for o in ltime] == [("src/POUs/FB_Base/FB_Base.impl.st", 2)]
    assert {o.obj for o in _occ(inv, "construct.new")} == {"F_Calc"}


def test_attributes_and_pragmas(inv: INV.Inventory) -> None:
    assert _total(inv, "attr.qualified_only") == 2  # E_Mode, GVL_Lib
    assert _total(inv, "attr.strict") == 1
    assert _total(inv, "attr.call_after_init") == 1
    assert _details(inv, "attr.symbol") == Counter({"read": 1})
    # {IF defined(DEBUG)} считается, {END_IF} — нет
    assert _details(inv, "pragma.conditional") == Counter({"IF defined(DEBUG)": 1})


def test_attribute_risk_comes_from_catalog() -> None:
    assert C.attribute_feature("pack_mode").risk == C.RISK_HIGH
    assert C.attribute_feature("Qualified_Only").id == "attr.qualified_only"
    unknown = C.attribute_feature("my_custom_flag")
    assert unknown.risk == C.RISK_MEDIUM
    assert unknown.refs == ()


def test_libraries_by_namespace_and_pou_names(inv: INV.Inventory) -> None:
    assert _details(inv, "lib.standard") == Counter({"Standard.LEN": 1, "TON": 1})
    assert _details(inv, "lib.util") == Counter({"Util.BLINK": 1})
    assert _details(inv, "lib.systime") == Counter({"SysTimeRtcHighResGet": 1})  # по префиксу функции
    assert _details(inv, "lib.caa_file") == Counter({"FILE.CAA": 1})
    assert _details(inv, "lib.pl") == Counter({"PL.FB_Motor": 1, "PL.I_Motor": 1, "PL.ST_Mem": 1, "PL.GVL_Const": 1})
    assert {o.subdir for o in _occ(inv, "lib.counit")} == {"tests"}
    assert _details(inv, "lib.counit") == Counter(
        {"coUnit.FB_TestSuite": 1, "coUnit.TEST": 1, "coUnit.TEST_FINISHED": 1, "AssertTrue": 1}
    )


def test_declared_name_shadows_namespace(inv: INV.Inventory) -> None:
    # Mem.iValue — переменная Mem, а не пространство имён MEM библиотеки CAA Memory
    assert _total(inv, "lib.caa_other") == 0


@pytest.mark.parametrize(
    ("fid", "expected"),
    [
        ("type.ltime", 2),  # ltLast : LTIME, FUNCTION F_Calc : LTIME
        ("type.ltime_literal", 2),  # LT#1S, LTIME#2MS
        ("type.ltime_conv", 1),  # TIME_TO_LTIME
        ("type.int64", 3),  # LWORD в ST_Ext и Helper, ULINT во флагмане
        ("type.wstring", 1),
        ("type.reference", 1),
        ("type.pointer", 2),  # pValue, pDyn
        ("type.struct", 2),
        ("type.struct_extends", 1),
        ("type.union", 1),
        ("type.enum", 1),
        ("type.enum_base", 1),
        ("type.alias", 1),
        ("type.subrange", 2),  # псевдоним T_Percent и поле iPct
    ],
)
def test_types(inv: INV.Inventory, fid: str, expected: int) -> None:
    assert _total(inv, fid) == expected


@pytest.mark.parametrize(
    ("fid", "expected"),
    [
        ("construct.var_in_out", 1),  # FB_Child
        ("construct.var_in_out_const", 1),  # FB_Base
        ("construct.var_stat", 1),
        ("construct.gvl_constant", 1),
        ("construct.gvl_mixed", 1),  # GVL_Lib: VAR_GLOBAL и VAR_GLOBAL CONSTANT в одном объекте
        ("construct.ltime_op", 1),
        ("construct.time_op", 1),
        ("construct.sizeof", 1),
        ("construct.adr", 1),
        ("construct.ref_assign", 1),
        ("construct.new", 2),  # __NEW, __DELETE
        ("construct.isvalidref", 1),
        ("construct.deref", 0),
    ],
)
def test_constructs(inv: INV.Inventory, fid: str, expected: int) -> None:
    assert _total(inv, fid) == expected


def test_retain_persistent_and_io(inv: INV.Inventory) -> None:
    assert _details(inv, "retain.retain") == Counter({"udiStarts": 1})
    assert _details(inv, "retain.persistent") == Counter({"lrHours": 1, "udiTrips": 1})
    assert _total(inv, "retain.pvl") == 1
    assert _details(inv, "io.at_wildcard") == Counter({"%I*": 1})
    assert _details(inv, "io.at_fixed") == Counter({"%QX0.1": 1})
    assert _details(inv, "io.at_memory") == Counter({"%MW10": 1})
    assert _details(inv, "io.direct") == Counter({"%ID4": 1})


def test_reserved_identifiers_and_vendor_prefix(inv: INV.Inventory) -> None:
    assert _details(inv, "ident.rusty") == Counter({"Override": 1})
    assert _details(inv, "ident.iec_checker") == Counter({"Override": 1, "Priority": 1})
    assert _details(inv, "ident.vendor_prefix") == Counter({"PsHelper": 1})


def test_occurrence_points_to_member_file(inv: INV.Inventory) -> None:
    (occ,) = _occ(inv, "construct.time_op")
    assert (occ.source, occ.subdir, occ.obj, occ.member) == ("lib", "src", "FB_Child", "Helper")
    assert occ.path == "src/POUs/FB_Child/Helper.method.impl.st"
    assert occ.line == 1


# ---------------------------------------------------------------------------
# Задачи, библиотеки из config.json, базовая линия
# ---------------------------------------------------------------------------


def test_tasks_from_config_json(inv: INV.Inventory) -> None:
    rows = {(t.mode, t.name): t for t in inv.tasks}
    # ExampleTask вызывает только PRG_Example — объект базовой линии, задача пропущена
    assert sorted(rows) == [("normal", "MainTask"), ("normal", "SlowTask"), ("test", "TestTask")]
    assert "зарезервированы" in rows[("normal", "MainTask")].remark
    assert "максимум 15" in rows[("normal", "SlowTask")].remark
    assert "ЦП II типа — от 5" in rows[("test", "TestTask")].remark
    assert _total(inv, "task.config") == 3


@pytest.mark.parametrize(
    ("priority", "fragment"),
    [
        (None, "не задан"),
        (0, "зарезервированы"),
        (8, "допустим на REGUL"),
        (15, "допустим на REGUL"),
        ("high", "не число"),
    ],
)
def test_task_remark(priority: Any, fragment: str) -> None:
    assert fragment in INV.task_remark(priority)


def test_libraries_from_config_json(inv: INV.Inventory) -> None:
    libs = {lib.key: lib for lib in inv.libraries}
    assert sorted(libs) == ["counit", "pl"]  # служебный ключ _doc пропущен
    assert libs["counit"].feature == "lib.counit"
    assert libs["counit"].modes == ["test"]
    assert libs["pl"].feature == "lib.pl"


def test_baseline_objects_and_tasks_are_skipped(inv: INV.Inventory) -> None:
    app = next(s for s in inv.sources if s.spec.id == "app")
    assert app.skipped == ["PRG_Example"]
    assert app.skipped_tasks == ["normal/ExampleTask"]
    assert "PRG_Example" not in {o.name for o in app.objects}


def test_without_baseline_everything_is_counted() -> None:
    inv = INV.run(_config(), str(FIXTURES), use_baseline=False)
    app = next(s for s in inv.sources if s.spec.id == "app")
    assert "PRG_Example" in {o.name for o in app.objects}
    assert ("normal", "ExampleTask") in {(t.mode, t.name) for t in inv.tasks}


def test_changed_baseline_object_is_counted(tmp_path: Path) -> None:
    root = tmp_path / "fx"
    shutil.copytree(FIXTURES, root)
    impl = root / "app" / "src" / "POUs" / "PRG_Example" / "PRG_Example.impl.st"
    impl.write_text("xRun := TRUE;\n", encoding="utf-8", newline="\n")
    inv = INV.run(_config(), str(root))
    app = next(s for s in inv.sources if s.spec.id == "app")
    assert app.skipped == []
    assert "PRG_Example" in {o.name for o in app.objects}


# ---------------------------------------------------------------------------
# Справочник
# ---------------------------------------------------------------------------


def _all_features() -> list[C.Feature]:
    return [*C.FEATURES.values(), *(C.attribute_feature(name) for name in C.ATTRIBUTES)]


def test_catalog_refs_resolve() -> None:
    tables: dict[str, dict[str, Any]] = {
        "fact": dict(C.FACTS),
        "risk": dict(C.RISKS),
        "checklist": dict(C.CHECKLIST),
        "section": dict(C.SECTIONS),
    }
    groups = {g for g, _ in C.GROUPS}
    for feat in _all_features():
        assert feat.risk in C.RISK_ORDER, feat.id
        assert feat.group in groups, feat.id
        for ref in feat.refs:
            assert ref in tables[C.ref_kind(ref)], (feat.id, ref)


def test_catalog_ids_follow_research_numbering() -> None:
    # факты F01–F93, риски R1–R23, чек-лист A1–J3 (по исследованию Astra.IDE)
    for fid in C.FACTS:
        assert re.fullmatch(r"F\d\d", fid) and 1 <= int(fid[1:]) <= 93, fid
    for rid in C.RISKS:
        assert re.fullmatch(r"R\d+", rid) and 1 <= int(rid[1:]) <= 23, rid
    for cid in C.CHECKLIST:
        assert re.fullmatch(r"[A-J]\d+", cid), cid
    for fact in C.FACTS.values():
        assert fact.url == "" or fact.url.startswith("https://"), fact


def test_catalog_maps_to_known_features() -> None:
    targets = [*C.NAMESPACES.values(), *C.LIBRARY_POUS.values(), *(fid for _, fid in C.SYSTEM_FUNCTION_PREFIXES)]
    for fid in targets:
        assert fid in C.FEATURES, fid
    for fid, _title, words, _src in C.RESERVED_SETS:
        assert fid in C.FEATURES
        assert words == frozenset(w.upper() for w in words)


def test_every_unresearched_feature_says_so() -> None:
    for feat in _all_features():
        if not feat.refs and feat.risk not in (C.RISK_NONE,):
            assert "исследовании нет" in feat.action, feat.id


# ---------------------------------------------------------------------------
# Отчёты
# ---------------------------------------------------------------------------


def test_markdown_report(inv: INV.Inventory) -> None:
    text = INV.render_markdown(inv, "out/inventory.json")
    assert text == INV.render_markdown(inv, "out/inventory.json")  # детерминирован
    assert text.endswith("\n") and not text.endswith("\n\n")
    for heading in ("## Источники", "## Главные риски", "## ООП", "## Задачи", "## Идентификаторы", "## Ссылки"):
        assert f"\n{heading}\n" in text
    # каждая ссылка на факт, риск или пункт чек-листа ведёт на якорь раздела «Ссылки»
    links = set(re.findall(r"\]\(#(ref-[a-z0-9]+)\)", text))
    anchors = set(re.findall(r'<a id="(ref-[a-z0-9]+)"></a>', text))
    assert links
    assert links <= anchors
    # в отчёте нет абсолютных путей
    assert str(FIXTURES) not in text
    assert not re.search(r"(?<![A-Za-z])[A-Za-z]:[\\/]", text)


def test_top_risks_sorted_by_risk_then_count(inv: INV.Inventory) -> None:
    text = INV.render_markdown(inv)
    section = text.split("## Главные риски", 1)[1].split("\n## ", 1)[0]
    risks = [line.split("|")[1].strip() for line in section.splitlines() if line.startswith("| ")][1:]
    order = [C.RISK_ORDER[r] for r in risks]
    assert order == sorted(order, reverse=True)
    assert risks[0] == C.RISK_HIGH


def test_json_report(inv: INV.Inventory) -> None:
    data = INV.build_json(inv)
    assert data["schema"] == INV.SCHEMA
    assert json.loads(INV.json_text(data)) == data
    ids = [f["id"] for f in data["features"]]
    assert len(ids) == len(set(ids))
    for feat in data["features"]:
        assert feat["total"] == sum(sum(by_dir.values()) for by_dir in feat["counts"].values())
        lines = sum(len(n) for by_path in feat["places"].values() for n in by_path.values())
        assert 0 < lines <= feat["total"] if feat["total"] else lines == 0
        for ref in feat["refs"]:
            if feat["total"]:
                assert ref in {**data["references"]["facts"], **data["references"]["risks"]} or ref in {
                    **data["references"]["checklist"],
                    **data["references"]["sections"],
                }
    sources = {s["id"]: s for s in data["sources"]}
    assert sources["app"]["skipped_baseline"] == ["PRG_Example"]
    assert sources["lib"]["rev"] == INV.WORKTREE
    assert sources["lib"]["stats"]["src"]["objects"]["function_block"] == 2
    time_op = next(f for f in data["features"] if f["id"] == "construct.time_op")
    assert time_op["places"] == {"lib": {"src/POUs/FB_Child/Helper.method.impl.st": [1]}}


def test_summary_counts_per_subdir(inv: INV.Inventory) -> None:
    summary = _summary(inv, "oop.extends_fb")
    assert summary.counts == {"lib": {"src": 1, "tests": 1}}
    assert summary.total == 2


def test_committed_report_matches_catalog() -> None:
    """docs/inventory.json в репозитории сделан текущей схемой и справочником."""
    path = REPO_ROOT / "docs" / "inventory.json"
    if not path.is_file():
        pytest.skip("docs/inventory.json ещё не создан")
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data["schema"] == INV.SCHEMA
    for feat in data["features"]:
        current = C.feature(feat["id"])
        assert (feat["risk"], tuple(feat["refs"])) == (current.risk, current.refs), feat["id"]


# ---------------------------------------------------------------------------
# Настройки
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        (None, ("HEAD",)),
        ("worktree", ()),
        ("", ()),
        ("integrate, main", ("integrate", "main")),
        (["integrate", "HEAD"], ("integrate", "HEAD")),
    ],
)
def test_parse_revs(value: Any, expected: tuple[str, ...]) -> None:
    assert INV.parse_revs(value) == expected


@pytest.mark.parametrize("value", [["worktree", "HEAD"], 5, ["a", 1]])
def test_parse_revs_rejects(value: Any) -> None:
    with pytest.raises(INV.InventoryError):
        INV.parse_revs(value)


def test_env_overrides_path_and_rev() -> None:
    text = FIXTURE_CONFIG.replace('path = "lib"', 'path = "lib"\npath_env = "X_LIB"\nrev_env = "X_REV"')
    config = _config(text, env={"X_LIB": "elsewhere", "X_REV": "integrate,main"})
    lib = config.sources[0]
    assert lib.tree == INV.TreeSpec("elsewhere", ("integrate", "main"))
    assert _config(text, env={"X_LIB": ""}).sources[0].tree.path == "lib"  # пустая переменная не считается


@pytest.mark.parametrize(
    ("text", "message"),
    [
        (FIXTURE_CONFIG + "\n[extra]\n", "неизвестные разделы"),
        (FIXTURE_CONFIG.replace('id = "app"', 'id = "lib"'), "повторяется"),
        (FIXTURE_CONFIG.replace('baseline = "base"', 'baseline = "nope"'), "нет базовой линии"),
        (FIXTURE_CONFIG.replace('id = "app"', 'id = "App"'), "коротким именем"),
        ('[output]\nmarkdown = "x.md"\n', "ни одного"),
    ],
)
def test_parse_config_errors(text: str, message: str) -> None:
    with pytest.raises(INV.InventoryError, match=message):
        _config(text)


def test_override_source() -> None:
    config = _config()
    changed = INV.override_source(config, "lib=other")
    assert changed.sources[0].tree == INV.TreeSpec("other", ())  # ревизия источника сохранена
    changed = INV.override_source(config, "lib=other@v1.0,HEAD")
    assert changed.sources[0].tree == INV.TreeSpec("other", ("v1.0", "HEAD"))
    changed = INV.override_source(config, "base=tpl@HEAD")
    assert changed.baselines["base"].tree == INV.TreeSpec("tpl", ("HEAD",))
    added = INV.override_source(config, "astra=../targets/astra")
    new = added.sources[-1]
    assert (new.id, new.tree, new.dirs, new.baseline) == (
        "astra",
        INV.TreeSpec("../targets/astra", ()),
        ("src", "tests"),
        None,
    )
    for bad in ("lib", "=x", "Bad=x"):
        with pytest.raises(INV.InventoryError):
            INV.override_source(config, bad)


# ---------------------------------------------------------------------------
# Ревизии git
# ---------------------------------------------------------------------------

needs_git = pytest.mark.skipif(shutil.which("git") is None, reason="нет git")


def _git(cwd: Path, *args: str) -> str:
    proc = subprocess.run(
        ["git", "-c", "user.name=test", "-c", "user.email=test@example.invalid", "-c", "core.autocrlf=false", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        check=True,
    )
    return proc.stdout


def _write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


@pytest.fixture()
def repo(tmp_path: Path) -> Path:
    root = tmp_path / "repo"
    _write(root / "src" / "POUs" / "F_A" / "F_A.decl.st", "// Назначение: проверка\nFUNCTION F_A : BOOL\n")
    _write(root / "src" / "POUs" / "F_A" / "F_A.impl.st", "F_A := TRUE;\n")
    _git(tmp_path, "init", "-q", "-b", "main", str(root))
    _git(root, "config", "core.autocrlf", "false")
    _git(root, "add", "-A")
    _git(root, "commit", "-q", "-m", "init")
    return root


def _single(path: str, rev: str) -> INV.Config:
    data = {"source": [{"id": "x", "path": path, "rev": rev, "dirs": ["src"]}]}
    return INV.parse_config(data, env={})


@needs_git
def test_committed_state_is_read_and_dirty_worktree_reported(repo: Path) -> None:
    _write(repo / "src" / "POUs" / "F_A" / "F_A.impl.st", "F_A := LTIME() > LT#0S;\n")  # не зафиксировано
    inv = INV.run(_single(str(repo), "HEAD"), str(repo.parent))
    (data,) = inv.sources
    assert data.snap.commit == _git(repo, "rev-parse", "HEAD").strip()
    assert data.snap.dirty is True
    assert data.snap.dirty_worktree == "repo"
    assert _total(inv, "construct.ltime_op") == 0
    text = INV.render_markdown(inv)
    assert "незафиксированные изменения" in text

    live = INV.run(_single(str(repo), "worktree"), str(repo.parent))
    assert _total(live, "construct.ltime_op") == 1
    assert live.sources[0].snap.commit is None


@needs_git
def test_first_existing_revision_is_used(repo: Path) -> None:
    inv = INV.run(_single(str(repo), "integrate,HEAD"), str(repo.parent))
    assert inv.sources[0].snap.rev == "HEAD"
    assert inv.sources[0].snap.dirty is False
    with pytest.raises(INV.InventoryError, match="нет ни одной из ревизий"):
        INV.run(_single(str(repo), "nope,also-nope"), str(repo.parent))


@needs_git
def test_branch_checked_out_in_other_worktree(repo: Path) -> None:
    _git(repo, "branch", "integrate")
    wt = repo.parent / "wt-integrate"
    _git(repo, "worktree", "add", "-q", str(wt), "integrate")
    _write(wt / "src" / "POUs" / "F_A" / "F_A.impl.st", "F_A := FALSE;\n")
    inv = INV.run(_single(str(repo), "integrate"), str(repo.parent))
    snap = inv.sources[0].snap
    # ветку видно из основной копии, а незафиксированные правки — в её рабочей копии
    assert snap.rev == "integrate"
    assert snap.dirty is True
    assert snap.dirty_worktree == "wt-integrate"


def test_missing_source_directory(tmp_path: Path) -> None:
    config = _single(str(tmp_path / "absent"), "worktree")
    with pytest.raises(INV.InventoryError, match="нет каталога"):
        INV.run(config, str(tmp_path))
    errors: list[str] = []

    class Sink:
        def write(self, text: str) -> None:
            errors.append(text)

    inv = INV.run(config, str(tmp_path), allow_missing=True, err=Sink())
    assert inv.sources == []
    assert any("пропущен" in e for e in errors)


# ---------------------------------------------------------------------------
# Командная строка
# ---------------------------------------------------------------------------


def test_main_writes_reports_and_checks_freshness(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    config = tmp_path / "inventory.toml"
    config.write_text(FIXTURE_CONFIG, encoding="utf-8")
    md = tmp_path / "inventory.md"
    js = tmp_path / "inventory.json"
    args = ["--root", str(FIXTURES), "--config", str(config), "--md", str(md), "--json", str(js)]
    assert INV.main(args) == 0
    assert "источников 2" in capsys.readouterr().out
    assert json.loads(js.read_text(encoding="utf-8"))["schema"] == INV.SCHEMA
    assert INV.main([*args, "--check"]) == 0
    md.write_text(md.read_text(encoding="utf-8") + "правка\n", encoding="utf-8")
    assert INV.main([*args, "--check"]) == 1
    assert "устарел" in capsys.readouterr().err


def test_main_reports_errors(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert INV.main(["--root", str(tmp_path), "--config", "absent.toml"]) == 1
    assert "нет файла настроек" in capsys.readouterr().err
    config = tmp_path / "inventory.toml"
    config.write_text(FIXTURE_CONFIG, encoding="utf-8")
    assert INV.main(["--root", str(FIXTURES), "--config", str(config), "--source", "broken"]) == 1


def test_fixture_files_are_lf_utf8() -> None:
    for path in FIXTURES.rglob("*"):
        if path.is_file():
            raw = path.read_bytes()
            assert b"\r\n" not in raw, path
            raw.decode("utf-8")
            assert not raw.startswith(b"\xef\xbb\xbf"), path


def test_relative_display_path() -> None:
    base = str(REPO_ROOT)
    assert INV.display_path("../plc-process-lib", base) == "../plc-process-lib"
    assert INV.display_path(os.path.join(base, "docs"), base) == "docs"


def test_unresearched_section_lists_checklist_only_features(inv: INV.Inventory) -> None:
    assert INV.is_researched(C.feature("oop.extends_fb"))  # F23, R15
    assert not INV.is_researched(C.feature("construct.var_in_out_const"))  # только пункт чек-листа C13
    text = INV.render_markdown(inv)
    section = text.split("## Не покрыто исследованием", 1)[1].split("\n## ", 1)[0]
    assert "`VAR_IN_OUT CONSTANT`" in section
    assert "[C13](#ref-c13)" in section
    assert "Наследование ФБ" not in section
