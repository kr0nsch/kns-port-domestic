"""Тесты tools/port_metrics.py: разложение строк, порог «переписан», маркеры PORT, отчёты.

Эталонный пример — tools/port_metrics_tests/fixtures/: оригиналы app/src (как флагман) и lib/src
(как библиотека), адаптированный код adapted/src. Ожидаемые числа посчитаны вручную по файлам
примера (комментарии у проверок).
"""

from __future__ import annotations

import json
import os
from collections.abc import Sequence
from pathlib import Path

import pytest
from hypothesis import given, settings
from hypothesis import strategies as st

import port_metrics as PM

HERE = Path(__file__).resolve().parent
FIXTURES = HERE / "fixtures"
REPO_ROOT = HERE.parent.parent
DOC = REPO_ROOT / "docs" / "port_metrics.md"


def _sources() -> tuple[list[PM.Source], list[PM.Source]]:
    base = str(REPO_ROOT)
    origs = [PM.parse_source(str(FIXTURES / "app" / "src"), base), PM.parse_source(str(FIXTURES / "lib" / "src"), base)]
    adapted = [PM.parse_source(str(FIXTURES / "adapted" / "src"), base)]
    return origs, adapted


def _fixture_report(with_comments: bool = False, exclude: Sequence[str] = ()) -> PM.Report:
    origs, adapted = _sources()
    report, errors = PM.build_report(origs, adapted, with_comments=with_comments, exclude=exclude, base=str(REPO_ROOT))
    assert errors == []
    return report


def _fixture_args(*extra: str) -> list[str]:
    return [
        "--orig",
        str(FIXTURES / "app" / "src"),
        "--orig",
        str(FIXTURES / "lib" / "src"),
        "--adapted",
        str(FIXTURES / "adapted" / "src"),
        *extra,
    ]


def _write_tree(root: Path, files: dict[str, str]) -> None:
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode("utf-8"))


def _obj(report: PM.Report, name: str) -> PM.ObjectResult:
    return next(o for o in report.objects if o.name == name)


def _file(report: PM.Report, suffix: str) -> PM.FileResult:
    return next(f for f in report.files if f.display.endswith(suffix))


# ---------------------------------------------------------------------------
# Пример целиком
# ---------------------------------------------------------------------------


def test_fixture_totals() -> None:
    report = _fixture_report()
    t = report.totals()
    # app: 55 строк оригинала (42 без изменений, 5 изменено, 3 переписано, 5 не перенесено);
    # lib: 19 (16 без изменений, 3 удалено); добавлено: 3 (app) + 2 (lib) + 16 (новые объекты)
    assert (t.orig, t.unchanged, t.changed, t.rewritten, t.removed, t.added) == (74, 58, 5, 3, 8, 21)
    assert t.unchanged + t.changed + t.rewritten + t.removed == t.orig
    assert t.adapted == 87
    by_label = {label: (c.orig, c.unchanged, c.removed, c.added, n) for label, c, n in report.by_label()}
    assert by_label == {
        "app": (55, 42, 5, 3, 5),
        "lib": (19, 16, 3, 2, 2),
        PM.NEW_LABEL: (0, 0, 0, 16, 3),
    }


def test_fixture_statuses() -> None:
    report = _fixture_report()
    statuses = {o.name: o.status for o in report.objects}
    assert statuses == {
        "E_PumpMode": PM.STATUS_CHANGED,
        "ST_PumpCfg": PM.STATUS_UNCHANGED,  # правка только в комментарии
        "FB_Old": PM.STATUS_REMOVED,
        "FB_Pump": PM.STATUS_CHANGED,  # d по сумме файлов = 1 - 23/31
        "PRG_Main": PM.STATUS_CHANGED,
        "F_Scale": PM.STATUS_CHANGED,
        "FB_Base": PM.STATUS_CHANGED,  # новый метод Init
        "GVL_Cfg": PM.STATUS_NEW,
        "F_Helper": PM.STATUS_NEW,
        "FB_VfdLink_Regul": PM.STATUS_NEW,
    }
    # Порядок: источники в порядке --orig, затем новые; внутри — DUTs, GVLs, Interfaces, POUs и имя
    assert [o.name for o in report.objects] == [
        "E_PumpMode",
        "ST_PumpCfg",
        "FB_Old",
        "FB_Pump",
        "PRG_Main",
        "F_Scale",
        "FB_Base",
        "GVL_Cfg",
        "F_Helper",
        "FB_VfdLink_Regul",
    ]
    stop = _file(report, "FB_Pump/Stop.method.impl.st")
    assert stop.status == PM.STATUS_REWRITTEN  # 1 строка из max(3, 4) без изменений: d = 0,75
    assert (stop.counts.rewritten, stop.counts.added) == (3, 1)
    prg = _file(report, "PRG_Main/PRG_Main.impl.st")
    assert prg.status == PM.STATUS_CHANGED  # d = 0,5 — ровно порог, не «переписан»
    assert prg.counts.difference == pytest.approx(0.5)
    scale = _file(report, "F_Scale/F_Scale.impl.st")
    assert (scale.status, scale.counts.removed, scale.counts.unchanged) == (PM.STATUS_CHANGED, 3, 4)


def test_fixture_markers_and_checks() -> None:
    report = _fixture_report()
    by_tag: dict[str, int] = {}
    for marker in report.markers:
        by_tag[marker.tag] = by_tag.get(marker.tag, 0) + 1
    assert by_tag == {"types": 1, "oop": 6, "other": 1, "build": 1, "io": 1, "hmi": 1, "comm": 1}
    implicit = sorted((m.tag, m.reason) for m in report.markers if not m.explicit)
    assert implicit == [
        ("comm", "адаптер связи с ПЧ через Modbus Serial Master вместо устройства CODESYS"),
        ("oop", "доступ к полю базы через экземпляр (наследование)"),
    ]
    unmarked = [(f.display.split("adapted/src/", 1)[1], h.line, h.kind) for f, h in report.unmarked]
    assert unmarked == [
        ("POUs/PRG_Main/PRG_Main.impl.st", 1, PM.HUNK_REPLACE),
        ("POUs/FB_Base/Init.method.decl.st", 1, PM.HUNK_FILE),
        ("POUs/FB_Base/Init.method.impl.st", 1, PM.HUNK_FILE),
        ("POUs/F_Helper/F_Helper.decl.st", 1, PM.HUNK_FILE),
    ]
    stale = [(m.path.rsplit("/", 1)[1], m.line) for m in report.stale_markers]
    assert stale == [("FB_Base.decl.st", 1)]
    problems = report.strict_problems()
    assert len(problems) == 6
    assert any("неизвестная категория [foo]" in p for p in problems)
    assert any("GVL_Cfg.gvl.st:2: маркер PORT без причины" in p for p in problems)


def test_with_comments_counts_comment_edits() -> None:
    plain = _fixture_report()
    with_comments = _fixture_report(with_comments=True)
    assert _obj(plain, "ST_PumpCfg").status == PM.STATUS_UNCHANGED
    cfg = _obj(with_comments, "ST_PumpCfg")
    assert cfg.status == PM.STATUS_CHANGED
    assert cfg.files[0].unmarked  # правка комментария без маркера
    # Заголовок FB_Pump и тело FB_Base («// Тела нет») становятся строками
    assert with_comments.totals().orig == plain.totals().orig + 2


def test_exclude_by_label_and_name() -> None:
    report = _fixture_report(exclude=["app:FB_Old", "f_helper"])
    names = {o.name for o in report.objects}
    assert "FB_Old" not in names and "F_Helper" not in names
    assert report.totals().removed == 3


# ---------------------------------------------------------------------------
# Сравнение одного файла
# ---------------------------------------------------------------------------


def test_identical_whitespace_and_marker_only_changes_are_unchanged() -> None:
    orig = "a := 1;\nIF a > 0 THEN\n    b := 2;\nEND_IF\n"
    adapted = "a  :=  1;   // PORT: [other] только пометка\n\tIF a > 0 THEN\n        b := 2;\nEND_IF\n"
    result = PM.compare_texts(orig, adapted)
    assert result.status == PM.STATUS_UNCHANGED
    assert result.counts.unchanged == 4
    assert [m.used for m in result.markers] == [False]  # маркер без правки


@pytest.mark.parametrize(
    ("changed", "threshold", "status"),
    [
        (1, 0.5, PM.STATUS_CHANGED),  # d = 0,25
        (2, 0.5, PM.STATUS_CHANGED),  # d = 0,5 — на пороге
        (3, 0.5, PM.STATUS_REWRITTEN),  # d = 0,75
        (2, 0.4, PM.STATUS_REWRITTEN),  # порог ниже
        (4, 0.99, PM.STATUS_REWRITTEN),
    ],
)
def test_rewritten_threshold(changed: int, threshold: float, status: str) -> None:
    orig_lines = [f"x{i} := {i};" for i in range(4)]
    new_lines = [f"y{i} := {i}; // PORT: [other] замена" if i < changed else line for i, line in enumerate(orig_lines)]
    result = PM.compare_texts("\n".join(orig_lines) + "\n", "\n".join(new_lines) + "\n", threshold=threshold)
    assert result.status == status
    c = result.counts
    assert c.unchanged + c.changed + c.rewritten + c.removed == 4
    if status == PM.STATUS_REWRITTEN:
        assert (c.rewritten, c.unchanged, c.changed) == (4, 0, 0)
    else:
        assert (c.changed, c.unchanged) == (changed, 4 - changed)
    assert not result.unmarked


def test_empty_original_and_empty_adapted_are_not_rewritten() -> None:
    grown = PM.compare_texts("// Тела нет\n", "a := 1;\nb := 2;\n")
    assert (grown.status, grown.counts.added, grown.counts.rewritten) == (PM.STATUS_CHANGED, 2, 0)
    emptied = PM.compare_texts("a := 1;\nb := 2;\n", "// пусто\n")
    assert (emptied.status, emptied.counts.removed) == (PM.STATUS_CHANGED, 2)
    both = PM.compare_texts("// было\n", "// стало\n")
    assert both.status == PM.STATUS_UNCHANGED


def test_marker_window_for_change_insert_and_delete() -> None:
    orig = "a := 1;\nb := 2;\nc := 3;\nd := 4;\ne := 5;\nf := 6;\ng := 7;\nh := 8;\n"
    # изменение b (маркер над строкой), вставка после d (маркер в строке), удаление f, g (маркер после)
    adapted = (
        "a := 1;\n"
        "// PORT: [types] причина изменения\n"
        "// поясняющий комментарий\n"
        "b := 20;\n"
        "c := 3;\n"
        "d := 4;\n"
        "x := 0; // PORT: [types] вставка\n"
        "e := 5;\n"
        "h := 8; // PORT: [types] удалены f и g\n"
    )
    result = PM.compare_texts(orig, adapted, threshold=0.9)
    assert result.status == PM.STATUS_CHANGED
    kinds = [(h.kind, h.marked) for h in result.hunks]
    assert kinds == [(PM.HUNK_REPLACE, True), (PM.HUNK_INSERT, True), (PM.HUNK_DELETE, True)]
    assert all(m.used for m in result.markers)
    # Маркер ниже участка изменения к нему не относится
    late = "a := 1;\nb := 20;\nc := 3; // PORT: [types] поздно\nd := 4;\ne := 5;\nf := 6;\ng := 7;\nh := 8;\n"
    result = PM.compare_texts(orig, late)
    assert [h.marked for h in result.hunks] == [False]
    assert [m.used for m in result.markers] == [False]


def test_deletion_at_start_and_end() -> None:
    orig = "a := 1;\nb := 2;\nc := 3;\nd := 4;\n"
    start = PM.compare_texts(orig, "// PORT: [other] удалена a\nb := 2;\nc := 3;\nd := 4;\n")
    assert [(h.kind, h.marked, h.line) for h in start.hunks] == [(PM.HUNK_DELETE, True, 1)]
    end = PM.compare_texts(orig, "a := 1;\nb := 2;\nc := 3;\n// PORT: [other] удалена d\n")
    assert [(h.kind, h.marked, h.line) for h in end.hunks] == [(PM.HUNK_DELETE, True, 3)]
    assert end.counts.removed == 1


def test_new_and_removed_files() -> None:
    new = PM.compare_texts(None, "// PORT: [io] адаптер\nFUNCTION F_X : BOOL\n")
    assert (new.status, new.counts.added, new.counts.orig) == (PM.STATUS_NEW, 1, 0)
    assert new.markers[0].used
    removed = PM.compare_texts("FUNCTION F_X : BOOL\n// комментарий\n", None)
    assert (removed.status, removed.counts.removed, removed.counts.adapted) == (PM.STATUS_REMOVED, 1, 0)
    with pytest.raises(ValueError):
        PM.compare_texts(None, None)


# ---------------------------------------------------------------------------
# Маркеры
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("comment", "expected"),
    [
        ("// PORT: [oop] композиция", ("oop", "композиция")),
        ("//PORT:[OOP]композиция", ("OOP", "композиция")),
        ("// PORT: без метки", (None, "без метки")),
        ("// PORT:", (None, "")),
        ("// PORT: [lib]", ("lib", "")),
        ("// Port: COM1", None),
        ("// порт PORT: позже", None),
        ("// PORTS: 2", None),
    ],
)
def test_parse_marker(comment: str, expected: tuple[str | None, str] | None) -> None:
    assert PM.parse_marker(comment) == expected


@pytest.mark.parametrize(
    ("raw_tag", "reason", "expected"),
    [
        ("OOP", "что угодно", ("oop", True)),
        ("foo", "что угодно", ("other", True)),
        (None, "EXTENDS не подтверждён", ("oop", False)),
        (None, "SUPER^ заменён вызовом", ("oop", False)),
        (None, "PERSISTENT через PersistentVars", ("retain", False)),
        (None, "атрибут не поддерживается", ("pragma", False)),
        (None, "фасад для OPC UA", ("opcua", False)),
        (None, "экраны WebVisu", ("hmi", False)),
        (None, "опрос по Modbus RTU", ("comm", False)),
        (None, "каналы RegulBus", ("io", False)),
        (None, "PsTimeGetUtcTimeNs вместо LTIME()", ("time", False)),
        (None, "тест на PsUnittest", ("test", False)),
        (None, "приоритет задачи 2..15", ("task", False)),
        (None, "библиотека CAA File недоступна", ("lib", False)),
        (None, "перечисление без базового типа", ("types", False)),
        (None, "ошибка компиляции C0032", ("build", False)),
        (None, "просто так", ("other", False)),
    ],
)
def test_classify(raw_tag: str | None, reason: str, expected: tuple[str, bool]) -> None:
    assert PM.classify(raw_tag, reason) == expected


def test_markers_only_in_line_comments() -> None:
    text = "s := '// PORT: [oop] в строке';\n(* PORT: [oop] в блоке *)\nx := 1; // PORT: [oop] настоящий\n"
    lines = PM.significant_lines(text)
    assert [(line, tag) for line, tag, _ in lines.markers] == [(3, "oop")]
    assert lines.lines == ["s := '// PORT: [oop] в строке';", "x := 1;"]
    assert lines.raw_numbers == [1, 3]


def test_every_category_has_unique_ascii_tag() -> None:
    tags = [cat.tag for cat in PM.CATEGORIES]
    assert len(tags) == len(set(tags))
    assert all(tag.isascii() and tag.islower() for tag in tags)
    assert tags[-1] == PM.OTHER_TAG


# ---------------------------------------------------------------------------
# Деревья: переименования, дубли, ошибки
# ---------------------------------------------------------------------------


def test_rename_map(tmp_path: Path) -> None:
    _write_tree(
        tmp_path,
        {
            "orig/src/POUs/FB_Link/FB_Link.decl.st": "FUNCTION_BLOCK FB_Link\nVAR\n    x : BOOL;\nEND_VAR\n",
            "orig/src/POUs/FB_Link/FB_Link.impl.st": "x := TRUE;\n",
            "new/src/POUs/FB_Link_Regul/FB_Link_Regul.decl.st": (
                "// PORT: [comm] драйвер REGUL\nFUNCTION_BLOCK FB_Link_Regul\nVAR\n    x : BOOL;\nEND_VAR\n"
            ),
            "new/src/POUs/FB_Link_Regul/FB_Link_Regul.impl.st": "x := TRUE;\n",
            "new/src/POUs/FB_Link/FB_Link.decl.st": "// PORT: [other] заглушка\nFUNCTION_BLOCK FB_Link\n",
            "new/src/POUs/FB_Link/FB_Link.impl.st": "// пусто\n",
        },
    )
    base = str(tmp_path)
    origs = [PM.parse_source(str(tmp_path / "orig" / "src"), base)]
    adapted = [PM.parse_source(str(tmp_path / "new" / "src"), base)]
    report, errors = PM.build_report(origs, adapted, renames=[("FB_Link", "FB_Link_Regul")], base=base)
    assert errors == []
    renamed = _obj(report, "FB_Link_Regul")
    assert (renamed.orig_name, renamed.status) == ("FB_Link", PM.STATUS_CHANGED)
    assert renamed.counts.changed == 1  # строка FUNCTION_BLOCK
    namesake = _obj(report, "FB_Link")
    assert (namesake.status, namesake.label) == (PM.STATUS_NEW, PM.NEW_LABEL)
    assert "FB_Link_Regul ← FB_Link" in PM.render_md(report)


def test_duplicate_objects_and_bad_map_give_warnings(tmp_path: Path) -> None:
    files = {
        "a/src/POUs/F_X/F_X.decl.st": "FUNCTION F_X : BOOL\n",
        "a/src/POUs/F_X/F_X.impl.st": "F_X := TRUE;\n",
        "b/src/POUs/F_X/F_X.decl.st": "FUNCTION F_X : BOOL\n",
        "b/src/POUs/F_X/F_X.impl.st": "F_X := FALSE;\n",
        "c/src/POUs/F_X/F_X.decl.st": "FUNCTION F_X : BOOL\n",
        "c/src/POUs/F_X/F_X.impl.st": "F_X := TRUE;\n",
    }
    _write_tree(tmp_path, files)
    base = str(tmp_path)
    origs = [PM.parse_source(str(tmp_path / d / "src"), base) for d in ("a", "b")]
    adapted = [PM.parse_source(str(tmp_path / "c" / "src"), base)]
    report, _ = PM.build_report(origs, adapted, renames=[("F_None", "F_Y")], base=base)
    assert _obj(report, "F_X").label == "a"  # взят первый оригинал
    assert _obj(report, "F_X").status == PM.STATUS_UNCHANGED
    assert any("есть в a и в b" in w and "--exclude b:F_X" in w for w in report.warnings)
    assert sum("--map F_None=F_Y" in w for w in report.warnings) == 2


def test_parse_source_label(tmp_path: Path) -> None:
    src = tmp_path / "kns-pump-station" / "src"
    src.mkdir(parents=True)
    default = PM.parse_source(str(src), str(tmp_path))
    assert (default.label, default.display) == ("kns-pump-station", "kns-pump-station/src")
    labelled = PM.parse_source(f"kns={src}", str(tmp_path))
    assert labelled.label == "kns"


# ---------------------------------------------------------------------------
# Командная строка и отчёты
# ---------------------------------------------------------------------------


def test_main_writes_reports(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    md, js = tmp_path / "m.md", tmp_path / "m.json"
    code = PM.main(_fixture_args("--md", str(md), "--json", str(js)))
    assert code == 0
    out = capsys.readouterr()
    assert "строк оригинала 74" in out.out
    assert "--exclude adapted:" not in out.err  # дублей нет
    text = md.read_text(encoding="utf-8")
    assert "| **Итого** | 10 | 74 | 58 (78,4 %) | 5 (6,8 %) | 3 (4,1 %) | 8 (10,8 %) | 21 | 87 |" in text
    assert "\n".join(PM.methodology_md()) in text
    data = json.loads(js.read_text(encoding="utf-8"))
    assert data["schema"] == PM.SCHEMA_VERSION
    assert data["totals"]["orig_lines"] == 74
    assert data["markers"]["total"] == 12
    assert data["markers"]["by_category"]["oop"] == {"markers": 6, "implicit": 1, "changes": 6, "checks": 0}
    assert len(data["files"]) == 29
    assert len(data["unmarked"]) == 4
    # Повторный запуск даёт тот же отчёт
    first = md.read_bytes(), js.read_bytes()
    assert PM.main(_fixture_args("--md", str(md), "--json", str(js), "-q")) == 0
    assert (md.read_bytes(), js.read_bytes()) == first


def test_report_has_no_absolute_paths(tmp_path: Path) -> None:
    md, js = tmp_path / "m.md", tmp_path / "m.json"
    assert PM.main(_fixture_args("--md", str(md), "--json", str(js), "-q")) == 0
    for path in (md, js):
        text = path.read_text(encoding="utf-8")
        assert str(REPO_ROOT) not in text and str(REPO_ROOT).replace(os.sep, "/") not in text
        assert str(tmp_path) not in text and tmp_path.as_posix() not in text
    command = json.loads(js.read_text(encoding="utf-8"))["params"]["command"]
    assert command == (
        "python tools/port_metrics.py --orig app=tools/port_metrics_tests/fixtures/app/src"
        " --orig lib=tools/port_metrics_tests/fixtures/lib/src"
        " --adapted adapted=tools/port_metrics_tests/fixtures/adapted/src"
    )


def test_main_strict_and_dry_run(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    md = tmp_path / "m.md"
    assert PM.main(_fixture_args("--strict", "--dry-run", "--md", str(md))) == 1
    err = capsys.readouterr().err
    assert "PRG_Main.impl.st:1: правка без маркера PORT (изменение)" in err
    assert not md.exists()


def test_main_errors(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert PM.main(["--orig", str(tmp_path / "none"), "--adapted", str(tmp_path), "--dry-run"]) == 2
    assert PM.main(_fixture_args("--threshold", "1.5", "--dry-run")) == 2
    assert PM.main(_fixture_args("--map", "broken", "--dry-run")) == 2
    assert PM.main(["--no-such-flag"]) == 2
    bad = {"bad/src/POUs/F_A/F_A.decl.st": "FUNCTION F_B : BOOL\n", "bad/src/POUs/F_A/F_A.impl.st": "\n"}
    _write_tree(tmp_path, bad)
    assert PM.main(_fixture_args("--adapted", str(tmp_path / "bad" / "src"), "--dry-run")) == 1
    assert "LAY002" in capsys.readouterr().err


def test_docs_report_contains_current_methodology() -> None:
    """docs/port_metrics.md содержит методику текущей версии инструмента (иначе — перегенерировать)."""
    assert "\n".join(PM.methodology_md()) in DOC.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Свойства
# ---------------------------------------------------------------------------

_LINES = st.lists(st.sampled_from(["a := 1;", "b := 2;", "c := 3;", "IF x THEN", "END_IF", "y();"]), max_size=12)


@settings(max_examples=200, deadline=None)
@given(orig=_LINES, adapted=_LINES, threshold=st.sampled_from([0.0, 0.25, 0.5, 0.75]))
def test_buckets_always_sum_to_original(orig: list[str], adapted: list[str], threshold: float) -> None:
    o = "".join(line + "\n" for line in orig)
    a = "".join(line + "\n" for line in adapted)
    result = PM.compare_texts(o, a, threshold=threshold)
    c = result.counts
    assert c.unchanged + c.changed + c.rewritten + c.removed == len(orig)
    assert (c.orig, c.adapted) == (len(orig), len(adapted))
    assert 0.0 <= c.difference <= 1.0
    if orig == adapted:
        assert result.status == PM.STATUS_UNCHANGED
    if result.status != PM.STATUS_REWRITTEN:
        # В адаптированном файле каждая строка либо совпала, либо пришла из правки
        assert c.unchanged + c.added <= len(adapted) <= c.unchanged + c.changed + c.added


# ---------------------------------------------------------------------------
# Маркеры проверки, пары деревьев, категории, --check
# ---------------------------------------------------------------------------


def test_check_marker_is_not_a_change_and_not_stale() -> None:
    orig = "a := 1;\nb := LTIME();\n"
    adapted = "a := 1;\n// PORT: [time] проверить в Astra.IDE — оператор LTIME(), монотонность (C11)\nb := LTIME();\n"
    result = PM.compare_texts(orig, adapted)
    assert result.status == PM.STATUS_UNCHANGED
    (marker,) = result.markers
    assert (marker.check, marker.items, marker.tag) == (True, ("C11",), "time")
    report = PM.Report(0.5, False, [], [], [PM.ObjectResult("F_X", "x", "FUNCTION", result.status, result.counts)])
    report.objects[0].files = [result]
    assert report.stale_markers == []
    assert [m.reason for m in report.check_markers] == [marker.reason]


def test_check_marker_does_not_mark_a_change() -> None:
    orig = "a := 1;\nb := 2;\n"
    adapted = "a := 1;\n// PORT: [oop] проверить в Astra.IDE — THIS^ (C2)\nb := 3;\n"
    result = PM.compare_texts(orig, adapted, threshold=0.9)
    assert [h.marked for h in result.hunks] == [False]
    marked = PM.compare_texts(
        orig, "a := 1;\n// PORT: [oop] проверить в Astra.IDE — THIS^ (C2)\nb := 3; // PORT: [oop] x\n"
    )
    assert [(h.marked, h.category) for h in marked.hunks] == [(True, "oop")]


@pytest.mark.parametrize(
    ("reason", "items"),
    [
        ("проверить в Astra.IDE — EXTENDS (C1)", ("C1",)),
        ("проверить в Astra.IDE — тип статуса [F58] (E2)", ("E2",)),
        ("проверить в Astra.IDE — визуализация (F1, F3)", ("F1", "F3")),
        ("проверить в Astra.IDE — факт (F58)", ()),
        ("правка без пункта", ()),
    ],
)
def test_marker_items(reason: str, items: tuple[str, ...]) -> None:
    assert PM.marker_items(reason) == items


def test_paired_trees_match_only_within_pair(tmp_path: Path) -> None:
    gvl = "{attribute 'qualified_only'}\nVAR_GLOBAL CONSTANT\n    X : INT := %d;\nEND_VAR\n"
    _write_tree(
        tmp_path,
        {
            "o/app/src/GVLs/GVL_Const.gvl.st": gvl % 1,
            "o/lib/src/GVLs/GVL_Const.gvl.st": gvl % 2,
            "a/app/src/GVLs/GVL_Const.gvl.st": gvl % 1,
            "a/lib/src/GVLs/GVL_Const.gvl.st": gvl % 2,
        },
    )
    base = str(tmp_path)
    origs = [
        PM.parse_source(f"app={tmp_path / 'o/app/src'}", base),
        PM.parse_source(f"lib={tmp_path / 'o/lib/src'}", base),
    ]
    adapted = [
        PM.parse_source(f"app={tmp_path / 'a/app/src'}", base),
        PM.parse_source(f"lib={tmp_path / 'a/lib/src'}", base),
    ]
    report, errors = PM.build_report(origs, adapted, base=base)
    assert errors == []
    assert report.warnings == []
    assert [(o.label, o.status) for o in report.objects] == [
        ("app", PM.STATUS_UNCHANGED),
        ("lib", PM.STATUS_UNCHANGED),
    ]


def test_category_stats_attribute_lines_and_files() -> None:
    report = _fixture_report()
    stats = {st.tag: st for st in PM.category_stats(report)}
    # comm: новый объект FB_VfdLink_Regul (маркер в объявлении) — все его строки добавлены
    vfd = _obj(report, "FB_VfdLink_Regul")
    assert stats["comm"].added_lines == vfd.counts.adapted
    assert stats["comm"].objects == {f"{PM.NEW_LABEL}:FB_VfdLink_Regul"}
    assert stats["comm"].changes == 1 and stats["comm"].checks == 0
    # строки категорий не больше общих итогов
    t = report.totals()
    assert sum(st.added_lines for st in stats.values()) <= t.added + t.unchanged
    assert sum(st.orig_lines for st in stats.values()) <= t.changed + t.rewritten + t.removed


def test_main_check_detects_stale_report(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    md, js = tmp_path / "m.md", tmp_path / "m.json"
    assert PM.main(_fixture_args("--md", str(md), "--json", str(js), "--check", "-q")) == 1
    assert "отчёт устарел" in capsys.readouterr().err
    assert not md.exists()
    assert PM.main(_fixture_args("--md", str(md), "--json", str(js), "-q")) == 0
    assert PM.main(_fixture_args("--md", str(md), "--json", str(js), "--check", "-q")) == 0
    data = json.loads(js.read_text(encoding="utf-8"))
    assert data["markers"]["checks"] == 0 and data["markers"]["changes"] == 12
    assert {row["category"] for row in data["categories"]} >= {"oop", "comm"}


def test_default_trees_are_this_repository_port() -> None:
    """Отчёт docs/port_metrics.md строится по деревьям по умолчанию: снимки upstream/ и targets/astra/."""
    assert any(
        s.startswith("kns-pump-station=") and s.endswith(os.path.join("upstream", "kns-pump-station", "src"))
        for s in PM.DEFAULT_ORIGS
    )
    assert PM.DEFAULT_EXCLUDE == ("plc-process-lib:PRG_Main",)
    data = json.loads((REPO_ROOT / "docs" / "port_metrics.json").read_text(encoding="utf-8"))
    assert data["params"]["command"].startswith("python tools/port_metrics.py --orig kns-pump-station=upstream/")
    assert data["unmarked"] == []
