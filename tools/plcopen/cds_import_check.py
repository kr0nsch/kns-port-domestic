# -*- coding: utf-8 -*-
"""Эталонная проверка PLCopen XML в CODESYS 3.5.17.30 (CODESYS Scripting, IronPython 2.7).

Скрипт выполняет CODESYS, его запускает `tools/plcopen/verify_codesys.py` (вручную не запускается):
    "<CODESYS.exe>" --profile="<профиль>" --noUI --runscript="tools/plcopen/cds_import_check.py"
Параметры — в файле задания JSON, путь к нему — в переменной окружения CDS_JOB:

    {
      "tools_codesys": "<repo>/tools/codesys",       общие модули CODESYS шаблона (только импорт)
      "device": {"name", "type", "id", "version"},   устройство проекта режима app
      "libraries": [описания библиотек cds.py],       ссылки в Library Manager (Standard)
      "result": "<путь>.json",                       итог
      "cases": [{"name", "xml", "mode": "app" | "pool", "project", "task"}]
    }

Режимы:
- app — пустой проект с устройством (`DeviceID(4096, '0000 0001', '3.5.17.30')`), импорт XML в
  приложение (`app.import_xml`), задача MainTask с программой `task` (если задана), полная сборка
  `app.rebuild()`: компилируются объекты, достижимые из задачи;
- pool — проект без устройства, импорт в пул POU (`proj.import_xml`), «Проверить все объекты пула»
  (`check_all_pool_objects`): компилируются все объекты, даже те, что никто не вызывает.

Итог по каждому случаю: сообщения импорта (ImportReporter), дерево импортированных объектов с
текстами объявлений и тел, сообщения компилятора и строка итога. Сравнение с исходниками и отчёт —
в verify_codesys.py. Модули шаблона (cds_common, import_sources, build, make_library) только
импортируются: библиотеки ищутся и подключаются тем же кодом, что у cds.py.

Синтаксис — общее подмножество Python 2.7 и 3.x (проверяет тест tools/plcopen/tests).
"""

from __future__ import absolute_import, print_function, unicode_literals

import io
import json
import os
import sys
import time
import traceback

JOB_ENV = 'CDS_JOB'
DUMP_KINDS = ('folder', 'pou', 'dut', 'gvl', 'pvl', 'itf', 'method', 'property', 'accessor', 'action')
TEXT_KINDS = ('pou', 'dut', 'gvl', 'pvl', 'itf', 'method', 'property', 'accessor', 'action')


def load_job():
    path = os.environ.get(JOB_ENV)
    if not path or not os.path.isfile(path):
        raise RuntimeError('нет файла задания (переменная %s): запускайте через verify_codesys.py' % JOB_ENV)
    with io.open(path, encoding='utf-8') as handle:
        return json.loads(handle.read())


JOB = load_job()
sys.path.insert(0, JOB['tools_codesys'])

import build as B  # noqa: E402
import cds_common as C  # noqa: E402
import import_sources as I  # noqa: E402
import make_library as ML  # noqa: E402

SE = C.api()


class Reporter(SE.ImportReporter):
    """Сообщения импорта PLCopen XML; конфликт имён — копия (в пустом проекте их быть не должно)."""

    def __init__(self):
        self.messages = []

    def error(self, message):
        self.messages.append({'level': 'error', 'text': C._text(message)})

    def warning(self, message):
        self.messages.append({'level': 'warning', 'text': C._text(message)})

    def resolve_conflict(self, obj):
        self.messages.append({'level': 'conflict', 'text': C.obj_name(obj)})
        return SE.ConflictResolve.Copy

    def added(self, obj):
        self.messages.append({'level': 'added', 'text': C.obj_name(obj)})

    def replaced(self, obj):
        self.messages.append({'level': 'replaced', 'text': C.obj_name(obj)})

    def skipped(self, objectname):
        self.messages.append({'level': 'skipped', 'text': C._text(objectname)})

    @property
    def aborting(self):
        return False


def dump_tree(container, path, out):
    """Объекты раскладки под container: путь (имена от container), вид, тексты объявления и тела."""
    for obj in C.children(container):
        kind = C.kind_of(obj)
        if kind not in DUMP_KINDS:
            continue
        name = C.obj_name(obj)
        item = {'path': path + [name], 'kind': kind}
        if kind in TEXT_KINDS:
            item['decl'] = C.decl_text(obj)
            item['impl'] = C.impl_text(obj)
        out.append(item)
        dump_tree(obj, path + [name], out)


def remove_quietly(path):
    try:
        if os.path.exists(path):
            os.remove(path)
    except Exception:
        pass


def project_side_files(project):
    """Файлы, которые CODESYS пишет рядом с проектом (.opt, кэш предкомпиляции)."""
    folder = os.path.dirname(project)
    stem = os.path.splitext(os.path.basename(project))[0]
    found = []
    if os.path.isdir(folder):
        for name in os.listdir(folder):
            if name.startswith(stem) and (name.endswith('.opt') or name.endswith('.precompilecache')):
                found.append(os.path.join(folder, name))
    return found


def run_case(case, resolved, log):
    result = {'name': case['name'], 'mode': case['mode'], 'xml': case['xml'], 'ok': False}
    project = case['project']
    C.ensure_dir(os.path.dirname(project))
    remove_quietly(project)
    for side in project_side_files(project):
        remove_quietly(side)
    started = time.time()
    proj = None
    try:
        proj = SE.projects.create(project, True)
        report = I.Report(log)
        if case['mode'] == 'app':
            dev = JOB['device']
            proj.add(dev['name'], SE.DeviceID(int(dev['type']), dev['id'], dev['version']))
            target = C.application(proj)
            libman = I.find_library_manager(target)
        else:
            target = proj
            libman = proj.get_library_manager()
        I.sync_libraries(libman, resolved, [], log, report)
        result['libraries'] = [C.ref_record(ref)['name'] for ref in libman.references]
        reporter = Reporter()
        try:
            target.import_xml(reporter, case['xml'], True)
        except Exception as exc:
            result['import_exception'] = C._text(exc)
        result['import_messages'] = reporter.messages
        objects = []
        dump_tree(target, [], objects)
        result['objects'] = objects
        if case.get('export'):
            # экспорт CODESYS того, что импортировано (с текстами объявлений) — для обратной проверки
            try:
                C.ensure_dir(os.path.dirname(case['export']))
                remove_quietly(case['export'])
                proj.export_xml([target], path=case['export'], recursive=True, export_folder_structure=True,
                                declarations_as_plaintext=True)
                result['export'] = case['export']
            except Exception as exc:
                result['export_error'] = C._text(exc)
        B.clear_messages()
        if case['mode'] == 'app':
            if case.get('task'):
                tasks = [{'name': 'MainTask', 'interval_ms': 20, 'pous': [case['task']]}]
                I.sync_tasks(target, tasks, log, report)
            target.rebuild()
            records = B.collect_messages()
        else:
            records = ML.check_pool(proj, log)['messages']
        result['messages'] = records
        result['summary'] = B.summarize(records)
        result['ok'] = True
    except Exception:
        result['error'] = traceback.format_exc()
    finally:
        if proj is not None:
            try:
                proj.close()
            except Exception:
                pass
        remove_quietly(project)
        for side in project_side_files(project):
            remove_quietly(side)
    result['seconds'] = round(time.time() - started, 1)
    return result


def main():
    result = {'cases': [], 'python': sys.version, 'started': time.strftime('%Y-%m-%dT%H:%M:%S')}
    code = 0
    log = C.Log(JOB.get('log'))
    try:
        resolved = I.resolve_libraries(JOB.get('libraries') or [], JOB.get('repository') or 'System', log)
        for case in JOB['cases']:
            log.info('случай %s (%s): %s' % (case['name'], case['mode'], case['xml']))
            result['cases'].append(run_case(case, resolved, log))
    except Exception:
        result['error'] = traceback.format_exc()
        code = 3
    finally:
        log.close()
    C.write_json(JOB['result'], result)
    sys.exit(code)


main()
