"""Тесты tools/st_to_plcopen.py: эталонный XML, цикл раскладка -> XML -> раскладка, экспорт CODESYS, XSD.

Фикстура `fixtures/constructs/` — по объекту на каждую поддерживаемую конструкцию (её же импортирует и
собирает в CODESYS `tools/plcopen/verify_codesys.py`). `fixtures/codesys_export/constructs-app.xml` — экспорт
CODESYS 3.5.17.30 приложения после импорта нашего XML («объявления как обычный текст»): по нему проверяется
обратное направление на настоящем файле CODESYS. Эталоны `golden/*.xml` обновляются так:
`UPDATE_GOLDEN=1 python -m pytest tools/plcopen/tests` — затем просмотрите дифф.
"""

from __future__ import annotations

import importlib.util
import os
import sys
import xml.etree.ElementTree as ET
from collections.abc import Iterator
from pathlib import Path
from types import ModuleType
from typing import Any

import pytest

import st_to_plcopen as S
import stlayout as L

TESTS_DIR = Path(__file__).resolve().parent
PLCOPEN_DIR = TESTS_DIR.parent
REPO_ROOT = PLCOPEN_DIR.parent.parent
FIXTURE = TESTS_DIR / "fixtures" / "constructs"
CODESYS_EXPORT = TESTS_DIR / "fixtures" / "codesys_export" / "constructs-app.xml"
GOLDEN = TESTS_DIR / "golden"
TIMESTAMP = "2026-01-01T00:00:00"
CDS = S.CDS

if str(PLCOPEN_DIR) not in sys.path:
    sys.path.insert(0, str(PLCOPEN_DIR))

import verify_codesys as V  # noqa: E402


def convert(root: Path = FIXTURE, /, **kwargs: object) -> S.Result:
    options = S.Options(project_name="constructs", timestamp=TIMESTAMP)
    for key, value in kwargs.items():
        setattr(options, key, value)
    return S.convert_layout(str(root), options)


def layout_files(objects: list[L.StObject]) -> dict[str, str]:
    return {path: text for obj in objects for path, text in L.object_files(obj, "src")}


def fixture_objects() -> list[L.StObject]:
    scanned = L.scan(str(FIXTURE), "src")
    assert scanned.ok, [i.message for i in scanned.issues]
    return list(scanned.objects)


def parse(xml_text: str) -> ET.Element:
    return ET.fromstring(xml_text)


def q(tag: str, ns: str = S.NS_0201) -> str:
    return f"{{{ns}}}{tag}"


def find_named(root: ET.Element, tag: str, name: str, ns: str = S.NS_0201) -> ET.Element:
    for elem in root.iter(q(tag, ns)):
        if elem.get("name") == name:
            return elem
    raise AssertionError(f"нет <{tag} name={name!r}>")


def data_named(elem: ET.Element, suffix: str, ns: str = S.NS_0201) -> list[ET.Element]:
    return [d for d in elem.iter(q("data", ns)) if d.get("name") == CDS + suffix]


def check_golden(name: str, text: str) -> None:
    path = GOLDEN / name
    if os.environ.get("UPDATE_GOLDEN"):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8", newline="\n")
    assert path.is_file(), f"нет эталона {path}: UPDATE_GOLDEN=1 python -m pytest tools/plcopen/tests"
    assert text == path.read_text(encoding="utf-8"), f"XML отличается от эталона {path.name}"


# ---------------------------------------------------------------------------
# Эталоны и детерминированность
# ---------------------------------------------------------------------------


def test_golden_default() -> None:
    result = convert()
    assert result.errors == []
    assert [i for i in result.issues if i.severity == "warning"] == []
    check_golden("constructs.xml", result.xml)


def test_golden_tc6_only() -> None:
    result = convert(plaintext=False)
    assert result.errors == []
    warnings = sorted(i.message for i in result.issues if i.severity == "warning")
    assert warnings == [
        "ABSTRACT у FB_DeviceBase в структурной части TC6 не передаётся",
        "ABSTRACT у Start в структурной части TC6 не передаётся",
        "секция VAR_INST в структурной части TC6 не передаётся",
    ]
    assert "InterfaceAsPlainText" not in result.xml
    check_golden("constructs-tc6only.xml", result.xml)


def test_output_is_deterministic() -> None:
    assert convert().xml == convert().xml


def test_namespace_option() -> None:
    xml_0200 = convert(namespace=S.NS_0200).xml
    assert parse(xml_0200).tag == q("project", S.NS_0200)
    assert xml_0200.replace(S.NS_0200, S.NS_0201) == convert().xml


def test_object_ids_are_unique_and_stable() -> None:
    root = parse(convert().xml)
    ids = [e.text or "" for e in root.iter(q("ObjectId"))] + [
        e.get("ObjectId") or "" for e in root.iter() if e.get("ObjectId") and e.tag != q("Object")
    ]
    assert len(ids) == len(set(ids))
    structure = [e.get("ObjectId") or "" for e in root.iter(q("Object"))]
    assert sorted(structure) == sorted(ids)


# ---------------------------------------------------------------------------
# Содержимое: каждая поддерживаемая конструкция
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def root() -> ET.Element:
    return parse(convert().xml)


def test_header(root: ET.Element) -> None:
    header = root.find(q("fileHeader"))
    assert header is not None
    assert header.get("creationDateTime") == TIMESTAMP
    assert header.get("productName") == S.PRODUCT_NAME
    content = root.find(q("contentHeader"))
    assert content is not None and content.get("name") == "constructs"


def test_top_level_layout(root: ET.Element) -> None:
    data_types = [e.get("name") for e in root.iterfind(f"{q('types')}/{q('dataTypes')}/{q('dataType')}")]
    assert data_types == [
        "E_Color",
        "E_Mode",
        "ST_Base",
        "ST_Derived",
        "T_Name",
        "T_Percent",
        "ST_MotorCmd",
        "ST_MotorSts",
    ]
    pous = [(e.get("name"), e.get("pouType")) for e in root.iterfind(f"{q('types')}/{q('pous')}/{q('pou')}")]
    assert pous == [
        ("F_Clamp", "function"),
        ("F_Noop", "function"),
        ("F_Sum", "function"),
        ("FB_Counter", "functionBlock"),
        ("PRG_Aux", "program"),
        ("PRG_Main", "program"),
        ("FB_DeviceBase", "functionBlock"),
        ("FB_Motor", "functionBlock"),
        ("FB_Valve", "functionBlock"),
    ]
    extensions = [d.get("name", "").removeprefix(CDS) for d in root.iterfind(f"{q('addData')}/{q('data')}")]
    assert extensions == ["union", *["globalvars"] * 3, *["interface"] * 4, "projectstructure"]


def test_enum_with_values_and_base_type(root: ET.Element) -> None:
    enum = find_named(root, "dataType", "E_Mode").find(f"{q('baseType')}/{q('enum')}")
    assert enum is not None
    values = [(v.get("name"), v.get("value")) for v in enum.iter(q("value"))]
    assert values == [("OutOfService", "0"), ("Auto", "1"), ("Manual", "2"), ("Local", "3")]
    assert enum.find(f"{q('baseType')}/{q('INT')}") is not None
    attributes = [a.get("Name") for a in find_named(root, "dataType", "E_Mode").iter(q("Attribute"))]
    assert attributes == ["qualified_only", "strict"]


def test_struct_members_types_and_initial_values(root: ET.Element) -> None:
    struct = find_named(root, "dataType", "ST_Base")
    members = {v.get("name"): v for v in struct.iter(q("variable"))}
    assert list(members) == ["xEnable", "iCount", "rValue_bar", "sName", "wsLabel", "aiData", "eMode"]
    assert members["sName"].find(f"{q('type')}/{q('string')}").get("length") == "32"  # type: ignore[union-attr]
    array = members["aiData"].find(f"{q('type')}/{q('array')}")
    assert array is not None
    dim = array.find(q("dimension"))
    assert dim is not None and (dim.get("lower"), dim.get("upper")) == ("0", "3")
    values = [v.get("value") for v in members["aiData"].iter(q("simpleValue"))]
    assert values == ["1", "2", "3", "4"]
    doc = members["xEnable"].find(f"{q('documentation')}/{{{S.NS_XHTML}}}xhtml")
    assert doc is not None and doc.text == " разрешение"


def test_trailing_comment_belongs_to_its_own_variable(root: ET.Element) -> None:
    """Комментарий в конце строки не переходит к следующей переменной (xDoRun, xConfirmed)."""
    gvl = find_named(root, "globalVars", "GVL_Io")
    docs = {
        v.get("name"): (v.findtext(f"{q('documentation')}/{{{S.NS_XHTML}}}xhtml") or None)
        for v in gvl.findall(q("variable"))
    }
    assert docs["xDiStart"] == " кнопка «Пуск»"
    assert docs["xDoRun"] is None
    counter = find_named(root, "pou", "FB_Counter")
    outputs = {v.get("name"): v for v in counter.iter(q("variable"))}
    assert outputs["udiCount"].findtext(f"{q('documentation')}/{{{S.NS_XHTML}}}xhtml") == " число фронтов"
    assert outputs["xConfirmed"].find(q("documentation")) is None


def test_struct_extends_alias_subrange_union(root: ET.Element) -> None:
    derived = find_named(root, "dataType", "ST_Derived")
    assert [e.text for e in derived.iter(q("Extends"))] == ["ST_Base"]
    members = {v.get("name"): v for v in derived.iter(q("variable"))}
    assert members["ltStamp"].find(f"{q('type')}/{q('derived')}").get("name") == "LTIME"  # type: ignore[union-attr]
    assert members["pData"].find(f"{q('type')}/{q('pointer')}/{q('baseType')}/{q('INT')}") is not None
    assert find_named(root, "dataType", "T_Name").find(f"{q('baseType')}/{q('string')}").get("length") == "20"  # type: ignore[union-attr]
    subrange = find_named(root, "dataType", "T_Percent").find(f"{q('baseType')}/{q('subrangeSigned')}")
    assert subrange is not None
    rng = subrange.find(q("range"))
    assert rng is not None and (rng.get("lower"), rng.get("upper")) == ("0", "100")
    union = find_named(root, "union", "U_Raw")
    assert [v.get("name") for v in union.findall(q("variable"))] == ["wWord", "aBytes"]


def test_global_variable_lists(root: ET.Element) -> None:
    const = find_named(root, "globalVars", "GVL_Const")
    assert const.get("constant") == "true"
    io = find_named(root, "globalVars", "GVL_Io")
    addresses = {v.get("name"): v.get("address") for v in io.findall(q("variable"))}
    assert addresses["xDiStart"] == "%IX0.0" and addresses["iAiLevel"] == "%IW2"
    mixed = data_named(io, "mixedattrsvarlist")
    assert len(mixed) == 1
    blocks = [(b.get("retain"), b.get("constant")) for b in mixed[0].iter(q("globalVars"))]
    assert blocks == [(None, None), ("true", None), (None, "true")]
    pvl = find_named(root, "globalVars", "PersistentVars")
    assert (pvl.get("persistent"), pvl.get("retain")) == ("true", "true")


def test_pou_interface_sections(root: ET.Element) -> None:
    counter = find_named(root, "pou", "FB_Counter").find(q("interface"))
    assert counter is not None
    sections = [(child.tag.split("}")[1], child.get("retain")) for child in counter if child.tag != q("addData")]
    assert sections == [
        ("inputVars", None),
        ("outputVars", None),
        ("inOutVars", None),
        ("localVars", None),
        ("localVars", "true"),
        ("tempVars", None),
        ("documentation", None),
    ]
    fsum = find_named(root, "pou", "F_Sum").find(q("interface"))
    assert fsum is not None
    assert fsum.find(f"{q('returnType')}/{q('LREAL')}") is not None
    inout = fsum.find(q("inOutVars"))
    assert inout is not None and inout.get("constant") == "true"
    var_type = inout.find(f"{q('variable')}/{q('type')}/{q('derived')}")
    assert var_type is not None and var_type.get("name") == "ARRAY[*] OF REAL"
    base = find_named(root, "pou", "FB_DeviceBase").find(q("interface"))
    assert base is not None and base.find(q("globalVars")) is not None  # VAR_STAT
    main = find_named(root, "pou", "PRG_Main")
    ref = next(v for v in main.iter(q("variable")) if v.get("name") == "refValue")
    assert ref.find(f"{q('type')}/{q('derived')}").get("name") == "REFERENCE TO REAL"  # type: ignore[union-attr]
    buf = next(v for v in main.iter(q("variable")) if v.get("name") == "arBuf")
    repeated = buf.find(f"{q('initialValue')}/{q('arrayValue')}/{q('value')}")
    assert repeated is not None and repeated.get("repetitionValue") == "3"


def test_st_bodies_are_verbatim(root: ET.Element) -> None:
    for obj in fixture_objects():
        if obj.kind != L.KIND_POU:
            continue
        body = find_named(root, "pou", obj.name).find(f"{q('body')}/{q('ST')}/{{{S.NS_XHTML}}}xhtml")
        assert body is not None
        assert body.text == obj.impl


def test_oop_extensions(root: ET.Element) -> None:
    valve = find_named(root, "pou", "FB_Valve")
    inheritance = data_named(valve, "pouinheritance")[0]
    assert [e.text for e in inheritance.iter(q("Extends"))] == ["FB_DeviceBase"]
    assert [e.text for e in inheritance.iter(q("Implements"))] == ["I_Positioner", "I_Lockable"]
    methods = [m.get("name") for d in data_named(valve, "method") for m in d.findall(q("Method"))]
    assert methods == ["Lock", "MoveTo", "Start", "Trace"]
    trace = next(m for d in data_named(valve, "method") for m in d.findall(q("Method")) if m.get("name") == "Trace")
    modifiers = trace.find(f"{q('interface')}/{q('addData')}/{q('data')}/{q('AccessModifiers')}")
    assert modifiers is not None and modifiers.get("Internal") == "true"
    motor = find_named(root, "pou", "FB_Motor")
    prop = next(p for d in data_named(motor, "property") for p in d.findall(q("Property")))
    accessors = [child.tag.split("}")[1] for child in prop if child.tag.endswith("Accessor")]
    assert accessors == ["SetAccessor", "GetAccessor"]  # порядок экспорта CODESYS
    getter = prop.find(q("GetAccessor"))
    assert getter is not None and getter.find(f"{q('interface')}/{q('localVars')}") is not None
    device = find_named(root, "Interface", "I_Device")
    assert [e.text for e in device.iter(q("Extends"))] == ["I_Resettable"]
    assert [m.get("name") for m in device.iter(q("Method"))] == ["Start"]
    props = {
        p.get("name"): [c.tag.split("}")[1] for c in p if c.tag.endswith("Accessor")]
        for p in device.iter(q("Property"))
    }
    assert props == {"Fault": ["GetAccessor"], "Mode": ["SetAccessor", "GetAccessor"]}


def test_project_structure_folders(root: ET.Element) -> None:
    structure = root.find(f"{q('addData')}/{q('data')}[@name='{CDS}projectstructure']/{q('ProjectStructure')}")
    assert structure is not None
    folders = {f.get("Name"): [o.get("Name") for o in f.findall(q("Object"))] for f in structure.iter(q("Folder"))}
    assert folders == {
        "Motor": ["ST_MotorCmd"],
        "Status": ["ST_MotorSts"],
        "Devices": ["FB_DeviceBase", "FB_Motor", "FB_Valve"],
    }
    motor_folder = next(f for f in structure.iter(q("Folder")) if f.get("Name") == "Motor")
    assert [f.get("Name") for f in motor_folder.findall(q("Folder"))] == ["Status"]
    motor = next(o for o in structure.iter(q("Object")) if o.get("Name") == "FB_Motor")
    assert [o.get("Name") for o in motor.findall(q("Object"))] == ["Describe", "FB_init", "Reset", "Start", "Starts"]
    assert parse(convert(folders=False).xml).find(f".//{q('ProjectStructure')}") is None


# ---------------------------------------------------------------------------
# Цикл раскладка -> XML -> раскладка и экспорт CODESYS
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("namespace", [S.NS_0201, S.NS_0200], ids=["tc6_0201", "tc6_0200"])
def test_roundtrip_layout_xml_layout(namespace: str) -> None:
    objects, issues = S.read_xml(convert(namespace=namespace).xml)
    assert issues == []
    assert layout_files(objects) == layout_files(fixture_objects())


def test_roundtrip_writes_identical_files(tmp_path: Path) -> None:
    objects, _ = S.read_xml(convert().xml)
    L.write_objects(objects, str(tmp_path), "src")
    for rel, text in layout_files(fixture_objects()).items():
        assert (tmp_path / rel).read_bytes() == (FIXTURE / rel).read_bytes(), rel
        assert text == (tmp_path / rel).read_text(encoding="utf-8")
    written = sorted(p.relative_to(tmp_path).as_posix() for p in tmp_path.rglob("*.st"))
    assert written == sorted(p.relative_to(FIXTURE).as_posix() for p in FIXTURE.rglob("*.st"))


def test_codesys_export_reads_back_to_the_same_layout() -> None:
    """Экспорт CODESYS 3.5.17.30 (приложение целиком, tc6_0200) -> раскладка = исходная раскладка.

    Файл получен verify_codesys.py: наш XML импортирован в CODESYS, приложение экспортировано обратно. Если
    фикстура constructs изменилась, обновите его: `python tools/plcopen/verify_codesys.py --case
    constructs=tools/plcopen/tests/fixtures/constructs --namespace tc6_0201` и скопируйте
    build/plcopen/export/constructs-0201-codesys.xml в fixtures/codesys_export/constructs-app.xml.
    """
    text = CODESYS_EXPORT.read_text(encoding="utf-8")
    assert 'productName="CODESYS"' in text
    objects, issues = S.read_xml(text)
    assert issues == []
    assert layout_files(objects) == layout_files(fixture_objects())


def test_read_xml_skips_non_st_bodies() -> None:
    root = parse(convert().xml)
    aux = find_named(root, "pou", "PRG_Aux")
    body = aux.find(q("body"))
    assert body is not None
    for child in list(body):
        body.remove(child)
    ET.SubElement(body, q("FBD"))
    objects, issues = S.read_xml(ET.tostring(root, encoding="unicode"))
    assert "PRG_Aux" not in {o.name for o in objects}
    assert [(i.severity, i.path, i.message) for i in issues] == [
        ("warning", "PRG_Aux", "тело на FBD: в раскладке только ST — объект пропущен")
    ]


def test_read_xml_requires_plaintext() -> None:
    objects, issues = S.read_xml(convert(plaintext=False).xml)
    assert objects == []
    assert issues and all(i.severity == "error" for i in issues)
    assert "нет текста объявления" in issues[0].message


# ---------------------------------------------------------------------------
# Типы и значения
# ---------------------------------------------------------------------------


def type_xml(text: str) -> str:
    return S.serialize(S.type_node(text)).split("\n", 1)[1].replace("\n", "").replace("  ", "")


@pytest.mark.parametrize(
    ("st_type", "expected"),
    [
        ("BOOL", "<type><BOOL /></type>"),
        ("DATE_AND_TIME", "<type><DT /></type>"),
        ("TIME_OF_DAY", "<type><TOD /></type>"),
        ("LTIME", '<type><derived name="LTIME" /></type>'),
        ("STRING", "<type><string /></type>"),
        ("WSTRING(80)", '<type><wstring length="80" /></type>'),
        ("STRING(GVL_Const.LEN)", '<type><string length="GVL_Const.LEN" /></type>'),
        (
            "UINT(1..10)",
            '<type><subrangeUnsigned><range lower="1" upper="10" /><baseType><UINT /></baseType>'
            "</subrangeUnsigned></type>",
        ),
        (
            "ARRAY[1..2, 0..3] OF INT",
            '<type><array><dimension lower="1" upper="2" /><dimension lower="0" upper="3" />'
            "<baseType><INT /></baseType></array></type>",
        ),
        ("ARRAY[*, *] OF BYTE", '<type><derived name="ARRAY[*,*] OF BYTE" /></type>'),
        ("POINTER TO ST_Base", '<type><pointer><baseType><derived name="ST_Base" /></baseType></pointer></type>'),
        ("REFERENCE TO INT", '<type><derived name="REFERENCE TO INT" /></type>'),
        ("Standard.TON", '<type><derived name="Standard.TON" /></type>'),
        ("ARRAY[0..1] OF ARRAY[0..2] OF REAL", None),
    ],
)
def test_type_mapping(st_type: str, expected: str | None) -> None:
    got = type_xml(st_type)
    if expected is None:
        assert got.count("<array>") == 2
    else:
        assert got == expected


@pytest.mark.parametrize(
    ("value", "expected"),
    [
        ("TRUE", '<simpleValue value="TRUE" />'),
        ("T#5S", '<simpleValue value="T#5S" />'),
        (
            "[1, 2]",
            '<arrayValue><value><simpleValue value="1" /></value><value><simpleValue value="2" /></value></arrayValue>',
        ),
        ("[3(0.0)]", '<arrayValue><value repetitionValue="3"><simpleValue value="0.0" /></value></arrayValue>'),
        (
            "(xA := TRUE, stB := (iC := 2))",
            '<structValue><value member="xA"><simpleValue value="TRUE" /></value><value member="stB">'
            '<structValue><value member="iC"><simpleValue value="2" /></value></structValue></value></structValue>',
        ),
        ("[(iC := 1), (iC := 2)]", None),
        ("GVL_Const.MAX_ITEMS * 2", '<simpleValue value="GVL_Const.MAX_ITEMS*2" />'),
    ],
)
def test_initial_values(value: str, expected: str | None) -> None:
    got = S.serialize(S.value_node(value)).split("\n", 1)[1].replace("\n", "").replace("  ", "")
    inner = got.removeprefix("<initialValue>").removesuffix("</initialValue>")
    if expected is None:
        assert inner.count("<structValue>") == 2 and inner.startswith("<arrayValue>")
    else:
        assert inner == expected


def test_escaping_in_text_and_attributes() -> None:
    xml_text = convert().xml
    root = parse(xml_text)
    aux = find_named(root, "pou", "PRG_Aux")
    values = {v.get("name"): v.findtext(f"{q('initialValue')}/{q('simpleValue')}") for v in aux.iter(q("variable"))}
    simple = {v.get("name"): v.find(f"{q('initialValue')}/{q('simpleValue')}") for v in aux.iter(q("variable"))}
    assert simple["wsMsg"] is not None and simple["wsMsg"].get("value") == "\"Задвижка <закрыта> & 'ok'\""
    assert simple["sMsg"] is not None and simple["sMsg"].get("value") == "'a$'b\"c <&>'"
    assert values["iCalls"] is None


# ---------------------------------------------------------------------------
# Замечания преобразования
# ---------------------------------------------------------------------------


def write_layout(root: Path, files: dict[str, str]) -> None:
    for rel, text in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8", newline="\n")


def test_invalid_xml_character_is_an_error(tmp_path: Path) -> None:
    write_layout(
        tmp_path,
        {
            "src/POUs/PRG_Main/PRG_Main.decl.st": "PROGRAM PRG_Main\nVAR\n    x : INT;\nEND_VAR\n",
            "src/POUs/PRG_Main/PRG_Main.impl.st": "x := 1; // \x01\n",
        },
    )
    result = convert(tmp_path)
    assert [i.message for i in result.errors] == ["недопустимый в XML символ U+0001 — уберите его из исходника"]
    assert "\x01" not in result.xml


def test_second_pvl_and_persistent_gvl_warn(tmp_path: Path) -> None:
    write_layout(
        tmp_path,
        {
            "src/GVLs/PVL_A.pvl.st": "VAR_GLOBAL PERSISTENT RETAIN\n    a : INT;\nEND_VAR\n",
            "src/GVLs/PVL_B.pvl.st": "VAR_GLOBAL PERSISTENT RETAIN\n    b : INT;\nEND_VAR\n",
            "src/GVLs/GVL_P.gvl.st": "VAR_GLOBAL PERSISTENT\n    c : INT;\nEND_VAR\n",
        },
    )
    messages = [i.message for i in convert(tmp_path).issues if i.severity == "warning"]
    assert any("второй список Persistent Variables" in m for m in messages)
    assert any("VAR_GLOBAL PERSISTENT в обычном GVL" in m for m in messages)


def test_layout_errors_stop_conversion(tmp_path: Path) -> None:
    write_layout(tmp_path, {"src/POUs/PRG_Main/PRG_Main.decl.st": "PROGRAM PRG_Main\n"})
    result = convert(tmp_path)
    assert result.xml == ""
    assert any(i.severity == "error" and "LAY003" in i.message for i in result.issues)


def test_tests_folder_and_duplicates(tmp_path: Path) -> None:
    write_layout(
        tmp_path,
        {
            "src/DUTs/E_A.dut.st": "TYPE E_A :\n(\n    One\n);\nEND_TYPE\n",
            "tests/DUTs/E_B.dut.st": "TYPE E_B :\n(\n    Two\n);\nEND_TYPE\n",
        },
    )
    options = S.Options(timestamp=TIMESTAMP)
    result = S.convert_layout(str(tmp_path), options, tests="tests")
    assert result.errors == []
    objects, _ = S.read_xml(result.xml)
    assert {(o.name, tuple(o.folder)) for o in objects} == {("E_A", ()), ("E_B", ("Tests",))}
    excluded = S.convert_layout(str(tmp_path), options, tests="tests", exclude=["e_b"])
    assert excluded.objects == 1


# ---------------------------------------------------------------------------
# Командная строка
# ---------------------------------------------------------------------------


def test_cli_writes_xml_and_reverse(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = tmp_path / "out.xml"
    code = S.main(["--root", str(FIXTURE), "--out", str(out), "--name", "constructs", "--timestamp", TIMESTAMP])
    assert code == S.EXIT_OK
    assert out.read_text(encoding="utf-8") == convert().xml
    assert S.main(["--reverse", str(out), "--to", str(tmp_path / "back"), "-q"]) == S.EXIT_OK
    back = L.scan(str(tmp_path / "back"), "src")
    assert layout_files(list(back.objects)) == layout_files(fixture_objects())
    capsys.readouterr()


def test_cli_reverse_reads_bom_file(tmp_path: Path) -> None:
    exported = tmp_path / "export.xml"
    exported.write_text("﻿" + CODESYS_EXPORT.read_text(encoding="utf-8"), encoding="utf-8")
    assert S.main(["--reverse", str(exported), "--to", str(tmp_path / "back"), "-q"]) == S.EXIT_OK
    assert (tmp_path / "back" / "src" / "GVLs" / "PersistentVars.pvl.st").is_file()


def test_cli_errors(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert S.main(["--root", str(FIXTURE), "--timestamp", "01.01.2026", "--out", str(tmp_path / "x.xml")]) == 2
    assert S.main(["--reverse", str(CODESYS_EXPORT)]) == S.EXIT_USAGE
    bad = tmp_path / "bad"
    write_layout(bad, {"src/POUs/PRG_Main/PRG_Main.decl.st": "PROGRAM PRG_Main\n"})
    assert S.main(["--root", str(bad), "--out", str(tmp_path / "y.xml")]) == S.EXIT_FAILED
    assert not (tmp_path / "y.xml").exists()
    not_xml = tmp_path / "not.xml"
    not_xml.write_text("<project", encoding="utf-8")
    assert S.main(["--reverse", str(not_xml), "--to", str(tmp_path)]) == S.EXIT_FAILED
    assert S.main(["--reverse", str(tmp_path / "missing.xml"), "--to", str(tmp_path)]) == S.EXIT_FAILED
    capsys.readouterr()


def test_default_timestamp_from_source_date_epoch() -> None:
    assert S.default_timestamp({"SOURCE_DATE_EPOCH": "1767225600"}) == "2026-01-01T00:00:00"
    assert len(S.default_timestamp({})) == len(TIMESTAMP)


# ---------------------------------------------------------------------------
# Схема TC6 2.01
# ---------------------------------------------------------------------------


@pytest.fixture(scope="module")
def xsd_path() -> Iterator[str]:
    pytest.importorskip("lxml.etree")
    try:
        yield S.fetch_xsd()
    except S.XsdError as exc:
        pytest.skip(f"схема TC6 2.01 недоступна: {exc}")


@pytest.mark.network
@pytest.mark.parametrize(
    "options",
    [{}, {"namespace": S.NS_0200}, {"plaintext": False}, {"folders": False}],
    ids=["tc6_0201", "tc6_0200", "tc6-only", "no-folders"],
)
def test_xsd_valid(xsd_path: str, options: dict[str, object]) -> None:
    assert S.validate_xsd(convert(**options).xml, xsd_path) == []


@pytest.mark.network
def test_xsd_rejects_broken_file(xsd_path: str) -> None:
    broken = convert().xml.replace("<fileHeader ", "<fileHeaderX ", 1)
    assert S.validate_xsd(broken, xsd_path) != []


@pytest.mark.network
def test_xsd_valid_for_codesys_export(xsd_path: str) -> None:
    assert S.validate_xsd(CODESYS_EXPORT.read_text(encoding="utf-8"), xsd_path) == []


def test_fetch_xsd_checks_hash_of_local_copy(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    fake = tmp_path / "tc6_xml_v201.xsd"
    fake.write_text("<xsd:schema/>", encoding="utf-8")
    monkeypatch.setenv(S.XSD_ENV, str(fake))
    with pytest.raises(S.XsdError, match="SHA-256"):
        S.fetch_xsd(str(tmp_path / "cache"))


def test_fetch_xsd_uses_valid_cache_without_network(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv(S.XSD_ENV, raising=False)
    cached = Path(S.XSD_DIR) / S.XSD_MEMBER
    if not cached.is_file() or S._sha256(cached.read_bytes()) != S.XSD_SHA256:
        pytest.skip("схема ещё не скачана в build/xsd")
    target = tmp_path / S.XSD_MEMBER
    target.write_bytes(cached.read_bytes())
    assert S.fetch_xsd(str(tmp_path), url="http://127.0.0.1:9/never") == str(target)


# ---------------------------------------------------------------------------
# verify_codesys.py без CODESYS: ожидаемое дерево, сравнение, отчёт
# ---------------------------------------------------------------------------


def test_expected_objects_of_fixture() -> None:
    expected = V.expected_objects(fixture_objects())
    kinds: dict[str, int] = {}
    for item in expected:
        kinds[item.kind] = kinds.get(item.kind, 0) + 1
    assert kinds == {
        "dut": 9,
        "folder": 3,
        "gvl": 2,
        "pvl": 1,
        "itf": 4,
        "method": 16,
        "property": 7,
        "accessor": 10,
        "pou": 9,
    }
    assert len(expected) == 61  # столько объектов CODESYS показал после импорта (verify_codesys.py)
    accessor = next(e for e in expected if e.path == ("Devices", "FB_Motor", "Starts", "Set"))
    assert (accessor.decl, accessor.impl) == (S.DEFAULT_ACCESSOR_DECL, "uiStarts := Starts;\n")
    itf_accessor = next(e for e in expected if e.path == ("I_Device", "Mode", "Set"))
    assert (itf_accessor.decl, itf_accessor.impl) == ("", None)


def test_compare_reports_every_kind_of_difference() -> None:
    expected = [
        V.Expected(("A",), "dut", "TYPE A : INT;\nEND_TYPE\n"),
        V.Expected(("F",), "folder"),
        V.Expected(("F", "P"), "pou", "PROGRAM P\n", "x := 1;\n"),
        V.Expected(("G",), "gvl", "VAR_GLOBAL\nEND_VAR\n"),
    ]
    dumped: list[dict[str, Any]] = [
        {"path": ["A"], "kind": "dut", "decl": "TYPE A : INT;\r\nEND_TYPE", "impl": None},
        {"path": ["F", "P"], "kind": "pou", "decl": "PROGRAM P\n", "impl": "x := 2;\n"},
        {"path": ["G"], "kind": "pvl", "decl": "", "impl": None},
        {"path": ["X"], "kind": "dut", "decl": "", "impl": None},
    ]
    result = V.compare(expected, dumped)
    assert not result.ok
    assert result.missing == ["F (folder)"]
    assert result.extra == ["X (dut)"]
    assert result.kind_mismatch == ["G: в CODESYS pvl, ожидался gvl"]
    assert result.text_mismatch == ["F.P: тело: строка 1: CODESYS 'x := 2;' / файл 'x := 1;'"]
    assert V.compare(expected[:1], dumped[:1]).ok


def test_roundtrip_differences_and_pvl_as_gvl() -> None:
    objects = fixture_objects()
    assert V.roundtrip_differences(objects, objects) == []
    pvl = next(o for o in objects if o.kind == L.KIND_PVL)
    gvl = V.pvl_as_gvl(pvl)
    assert gvl.kind == L.KIND_GVL and "PERSISTENT" not in gvl.decl and "VAR_GLOBAL RETAIN" in gvl.decl
    changed = [o for o in objects if o is not pvl] + [gvl]
    diffs = V.roundtrip_differences(objects, changed)
    assert diffs == [
        "src/GVLs/PersistentVars.gvl.st: лишний файл из экспорта CODESYS",
        "src/GVLs/PersistentVars.pvl.st: нет в экспорте CODESYS",
    ]


def test_prepare_and_job_without_codesys(tmp_path: Path) -> None:
    case = V.prepare("constructs", FIXTURE, "tc6_0201", tmp_path)
    assert (
        case.xml.read_text(encoding="utf-8")
        == S.convert_layout(str(FIXTURE), S.Options(project_name="constructs", timestamp=V.TIMESTAMP)).xml
    )
    assert case.task == "PRG_Main"
    assert case.pool_xml is not None and case.pool_objects is not None
    pool_kinds = {o.name: o.kind for o in case.pool_objects}
    assert pool_kinds["PersistentVars"] == L.KIND_GVL
    tc6 = V.prepare("constructs", FIXTURE, "tc6_0200", tmp_path, plaintext=False)
    assert tc6.label == "tc6_0200-tc6only" and tc6.xml.name == "constructs-0200-tc6only.xml"


def test_cli_dry_run(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    code = V.main(["--case", f"constructs={FIXTURE}", "--out", str(tmp_path), "--dry-run", "--structural"])
    if code == V.EXIT_ENV:
        pytest.skip("нет tools/codesys/config.json или CODESYS не описан")
    assert code == V.EXIT_OK
    job = (tmp_path / "verify-job.json").read_text(encoding="utf-8")
    assert '"mode": "pool"' in job and "constructs-0200-tc6only.xml" in job
    assert V.main(["--case", "broken"]) == V.EXIT_USAGE
    capsys.readouterr()


def test_report_lines() -> None:
    clean = V.CaseReport("c", "tc6_0201", "app", "c.xml", [], [], V.Comparison(3, 3), [], [], None, roundtrip=[])
    lossy = V.CaseReport(
        "c",
        "tc6_0201-tc6only",
        "pool",
        "c.xml",
        [],
        [],
        V.Comparison(3, 3),
        ["Error C0046 x"],
        [],
        None,
        informational=True,
    )
    assert clean.ok and clean.verdict == "OK"
    assert not lossy.ok and lossy.verdict == "потери TC6"
    lines = V.report_lines([clean, lossy], markdown=True)
    assert lines[2].endswith("| совпадает | OK |")
    assert lines[3].endswith("| — | потери TC6 |")
    assert "- компилятор: Error C0046 x" in lines


# ---------------------------------------------------------------------------
# Скрипт CODESYS — общее подмножество Python 2.7 и 3.x
# ---------------------------------------------------------------------------


def _py27_checker() -> ModuleType:
    tests_dir = REPO_ROOT / "tools" / "tests"
    if str(tests_dir) not in sys.path:
        sys.path.insert(0, str(tests_dir))
    spec = importlib.util.spec_from_file_location("plcopen_py27_compat", tests_dir / "test_py27_compat.py")
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_codesys_script_is_py27_compatible() -> None:
    checker = _py27_checker()
    assert checker.problems_of(PLCOPEN_DIR / "cds_import_check.py") == []
