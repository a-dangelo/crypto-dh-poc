#!/usr/bin/env python3
"""Record the shared-runtime endpoint audit; do not rerun or attest extraction."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ALLOWED = {'propext', 'Classical.choice', 'Quot.sound'}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def audit_reports(text, expected):
    assert not re.search(r'(?m)^.*\berror:', text), 'Lean audit log contains an error'
    reports = {}
    for name, axioms in re.findall(r"'([^']+)' depends on axioms: \[([^\]]*)\]", text):
        assert name not in reports, f'Duplicate endpoint report: {name}'
        reports[name] = sorted(a.strip() for a in axioms.split(',') if a.strip())
    for name in re.findall(r"'([^']+)' does not depend on any axioms", text):
        assert name not in reports, f'Duplicate endpoint report: {name}'
        reports[name] = []
    assert set(reports) == set(expected), 'Endpoint coverage differs from AxiomAudit.lean'
    for name, axioms in reports.items():
        assert set(axioms) <= ALLOWED, f'Unexpected axioms for {name}: {axioms}'
    return reports


def main():
    root = Path(__file__).resolve().parents[1]
    repo = root.parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lake-root', type=Path, default=repo / 'docs')
    args = parser.parse_args()
    lake_root = args.lake_root.resolve()
    assert lake_root == repo / 'docs', 'Expected the common book Lake environment'
    lock = json.loads((root / 'patches/toolchain.json').read_text())
    runtime = root / 'vendor/aeneas'
    assert (runtime / '.git').exists(), 'Missing pinned runtime repository'
    revision = subprocess.check_output(['git', '-C', str(runtime), 'rev-parse', 'HEAD'], text=True).strip()
    assert revision == lock['aeneas_revision'], 'Wrong shared runtime base'
    runtime_hashes = {name: sha(runtime / 'backends/lean' / name) for name in lock['runtime_files']}
    assert runtime_hashes == lock['runtime_files'], 'Shared runtime differs from the pinned patch'
    assert sha(root / 'patches/aeneas-probabilistic.patch') == lock['patch_sha256']
    assert (lake_root / 'lean-toolchain').read_text().strip() == 'leanprover/lean4:v4.35.0'
    assert '../Examples/HashCommitment/vendor/aeneas/backends/lean' in (lake_root / 'lakefile.lean').read_text()
    audit = root / 'lean/AxiomAudit.lean'
    expected = re.findall(r'^#print axioms (\S+)', audit.read_text(), re.M)
    assert expected and len(expected) == len(set(expected)), 'Missing or duplicate audit endpoints'
    log = root / 'evidence/blueprint-axioms.log'
    reports = audit_reports(log.read_text(), expected)
    standalone = root / 'evidence/manifest.json'
    assert standalone.is_file(), 'Missing standalone extraction/check provenance'
    source_files = sorted((root / 'lean/HashCommitment').rglob('*.lean'))
    source_files += [root / 'lean/HashCommitment.lean', audit]
    source_hashes = {str(p.relative_to(root)): sha(p) for p in source_files}
    standalone_data = json.loads(standalone.read_text())
    for name, digest in source_hashes.items():
        assert standalone_data['files'].get(name) == digest, f'Source differs from standalone provenance: {name}'
    output = {
        'schema': 1,
        'scope': 'Endpoint axiom audit in the common book runtime; no extraction rerun.',
        'standalone_manifest_sha256': sha(standalone),
        'aeneas_base': revision,
        'runtime_files': runtime_hashes,
        'patch_sha256': lock['patch_sha256'],
        'lean_toolchain': (lake_root / 'lean-toolchain').read_text().strip(),
        'shared_lakefile_sha256': sha(lake_root / 'lakefile.lean'),
        'shared_lake_manifest_sha256': sha(lake_root / 'lake-manifest.json'),
        'audit_log_sha256': sha(log),
        'source_files': source_hashes,
        'endpoint_axioms': reports,
    }
    (root / 'evidence/shared-audit.json').write_text(json.dumps(output, indent=2) + '\n')
    print(f'Recorded {len(reports)} shared-runtime endpoint audits; extraction provenance retained separately.')


if __name__ == '__main__':
    main()
