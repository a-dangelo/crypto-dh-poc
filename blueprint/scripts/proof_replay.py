#!/usr/bin/env python3
"""Record and validate a proof replay from this build, never from a prior source tree."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import subprocess

DOC = Path(__file__).resolve().parents[1]
ROOT = DOC.parent
STEPS = {
    'proof-build.log': ['lake', 'build', 'Concrete', 'DhPoc'],
    'concrete-axioms.log': ['lake', 'env', 'lean', '../scripts/check-concrete-axioms.lean'],
    'generic-axioms.log': ['lake', 'env', 'lean', '../scripts/check-generic-axioms.lean'],
    'parameterized-axioms.log': ['lake', 'env', 'lean', '../scripts/check-parameterized-axioms.lean'],
}


def source_checks():
    spec = importlib.util.spec_from_file_location('check_sources', DOC / 'scripts/check-sources.py')
    checks = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(checks)
    return checks


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_logs(directory, checks):
    checks.check_axioms(directory / 'concrete-axioms.log', directory / 'generic-axioms.log')
    subprocess.run(['python3', str(ROOT / 'scripts/check-parameterized-axioms.py'),
                    str(directory / 'parameterized-axioms.log')], check=True)


def check_replay(directory):
    checks = source_checks()
    checks.check_sources()
    replay = json.loads((directory / 'replay.json').read_text())
    assert replay['kind'] == 'current-build-proof-only-replay'
    assert replay['source_manifest_sha256'] == sha(DOC / 'current-source-manifest.json')
    assert replay['steps'] == {
        name: {'command': command, 'working_directory': 'concrete', 'exit_code': 0}
        for name, command in STEPS.items()
    }, 'Missing or failed current replay step'
    assert set(replay['log_sha256']) == set(STEPS), 'Incomplete current replay logs'
    for name, digest in replay['log_sha256'].items():
        assert sha(directory / name) == digest, f'Changed current replay log: {name}'
    check_logs(directory, checks)
    return replay


def run_replay(directory):
    directory.mkdir(parents=True, exist_ok=True)
    # A failed attempt must never leave a prior successful report in place.
    (directory / 'replay.json').unlink(missing_ok=True)
    checks = source_checks()
    checks.check_sources()
    manifest_hash = sha(DOC / 'current-source-manifest.json')
    steps = {}
    for name, command in STEPS.items():
        path = directory / name
        with path.open('w') as log:
            result = subprocess.run(command, cwd=ROOT / 'concrete', stdout=log,
                                    stderr=subprocess.STDOUT)
        print(path.read_text(), end='', flush=True)
        result.check_returncode()
        steps[name] = {'command': command, 'working_directory': 'concrete',
                       'exit_code': result.returncode}
    checks.check_sources()
    assert manifest_hash == sha(DOC / 'current-source-manifest.json'), 'Sources changed during replay'
    check_logs(directory, checks)
    replay = {
        'kind': 'current-build-proof-only-replay',
        'source_manifest_sha256': manifest_hash,
        'steps': steps,
        'log_sha256': {name: sha(directory / name) for name in STEPS},
        'scope': 'Lean targets Concrete and DhPoc; current concrete, generic and parameterized axiom audits.',
        'rust_extraction_rerun': False,
        'rust_native_checks_rerun': False,
        'blueprint_render_verified': False,
    }
    (directory / 'replay.json').write_text(json.dumps(replay, indent=2) + '\n')
    try:
        check_replay(directory)
    except Exception:
        (directory / 'replay.json').unlink(missing_ok=True)
        raise


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory', required=True, type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    directory = args.directory.resolve()
    if args.check:
        check_replay(directory)
    else:
        run_replay(directory)
