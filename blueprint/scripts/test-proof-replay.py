#!/usr/bin/env python3
"""Regression-test replay provenance with synthetic commands, never as proof evidence."""
from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import proof_replay as replay


class ReplayTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.doc = self.root / 'blueprint'
        self.doc.mkdir()
        (self.root / 'concrete').mkdir()
        self.manifest = self.doc / 'current-source-manifest.json'
        self.manifest.write_text('{"fixture": true}\n')
        self.out = self.root / 'test-output'
        self.calls = []
        self.failed = None
        self.change_manifest = False
        self.reject_audit = False
        self.source_checks_count = 0
        self.addCleanup(patch.stopall)
        patch.object(replay, 'DOC', self.doc).start()
        patch.object(replay, 'ROOT', self.root).start()
        patch.object(replay, 'source_checks', return_value=self).start()
        patch.object(replay.subprocess, 'run', side_effect=self.command).start()

    def check_sources(self):
        self.source_checks_count += 1
        return {}, {}

    def check_axioms(self, concrete, generic):
        self.assertEqual(concrete.read_text(), 'fixture concrete-axioms.log\n')
        self.assertEqual(generic.read_text(), 'fixture generic-axioms.log\n')
        if self.reject_audit:
            raise AssertionError('fixture audit rejected')
        return 22, 16

    def command(self, command, **kwargs):
        if command[0] == 'python3':
            self.assertEqual(Path(command[1]), self.root / 'scripts/check-parameterized-axioms.py')
            self.assertEqual(Path(command[2]).read_text(), 'fixture parameterized-axioms.log\n')
            return subprocess.CompletedProcess(command, 0)
        name = next(name for name, expected in replay.STEPS.items() if command == expected)
        self.calls.append(name)
        self.assertEqual(kwargs['cwd'], self.root / 'concrete')
        kwargs['stdout'].write('fixture ' + name + '\n')
        if self.change_manifest:
            self.manifest.write_text('{"fixture": "changed"}\n')
        return subprocess.CompletedProcess(command, 1 if name == self.failed else 0)

    def run_success(self):
        with redirect_stdout(io.StringIO()):
            replay.run_replay(self.out)
        return json.loads((self.out / 'replay.json').read_text())

    def test_success_uses_all_current_commands(self):
        result = self.run_success()
        self.assertEqual(self.calls, list(replay.STEPS))
        self.assertGreaterEqual(self.source_checks_count, 3)
        self.assertEqual(result['source_manifest_sha256'], replay.sha(self.manifest))
        self.assertFalse(result['rust_extraction_rerun'])
        self.assertFalse(result['rust_native_checks_rerun'])
        self.assertFalse(result['blueprint_render_verified'])
        replay.check_replay(self.out)

    def test_rejects_stale_manifest(self):
        self.run_success()
        self.manifest.write_text('changed\n')
        with self.assertRaises(AssertionError):
            replay.check_replay(self.out)

    def test_rejects_changed_or_missing_log(self):
        for name in replay.STEPS:
            with self.subTest(name=name):
                self.run_success()
                (self.out / name).write_text('tampered\n')
                with self.assertRaises(AssertionError):
                    replay.check_replay(self.out)
                (self.out / name).unlink()
                with self.assertRaises(FileNotFoundError):
                    replay.check_replay(self.out)

    def test_rejects_missing_or_failed_step(self):
        for mutation in ['missing', 'failed']:
            with self.subTest(mutation=mutation):
                result = self.run_success()
                if mutation == 'missing':
                    del result['steps']['proof-build.log']
                else:
                    result['steps']['proof-build.log']['exit_code'] = 1
                (self.out / 'replay.json').write_text(json.dumps(result))
                with self.assertRaises(AssertionError):
                    replay.check_replay(self.out)

    def test_failed_command_removes_stale_success(self):
        for name in replay.STEPS:
            with self.subTest(name=name):
                self.failed = None
                self.run_success()
                self.failed = name
                with self.assertRaises(subprocess.CalledProcessError), redirect_stdout(io.StringIO()):
                    replay.run_replay(self.out)
                self.assertFalse((self.out / 'replay.json').exists())

    def test_source_mutation_cannot_produce_report(self):
        self.change_manifest = True
        with self.assertRaises(AssertionError), redirect_stdout(io.StringIO()):
            replay.run_replay(self.out)
        self.assertFalse((self.out / 'replay.json').exists())

    def test_preflight_failure_removes_stale_success(self):
        self.run_success()
        with patch.object(self, 'check_sources', side_effect=AssertionError('fixture source mismatch')):
            with self.assertRaises(AssertionError):
                replay.run_replay(self.out)
        self.assertFalse((self.out / 'replay.json').exists())

    def test_final_validation_failure_removes_report(self):
        with patch.object(replay, 'check_replay', side_effect=AssertionError('fixture final mismatch')):
            with self.assertRaises(AssertionError), redirect_stdout(io.StringIO()):
                replay.run_replay(self.out)
        self.assertFalse((self.out / 'replay.json').exists())

    def test_audit_failure_cannot_produce_report(self):
        self.reject_audit = True
        with self.assertRaises(AssertionError), redirect_stdout(io.StringIO()):
            replay.run_replay(self.out)
        self.assertFalse((self.out / 'replay.json').exists())


if __name__ == '__main__':
    unittest.main()
