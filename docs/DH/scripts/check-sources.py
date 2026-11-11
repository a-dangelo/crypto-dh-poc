#!/usr/bin/env python3
"""Check current sources separately from the preserved historical snapshot."""
from pathlib import Path
import argparse
import hashlib
import json
import re

DOC = Path(__file__).resolve().parents[1]
ROOT = DOC.parents[1] / "Examples/DH"

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def check_sources():
    historical = json.loads((DOC / 'source-manifest.json').read_text())
    current = json.loads((DOC / 'current-source-manifest.json').read_text())
    assert historical['source_commit'] == (DOC / 'source-revision').read_text().strip()
    assert current['base_source_commit'] == historical['source_commit']
    assert len(historical['files']) == 67
    overrides = current['historical_path_overrides']
    historical_files = {entry['path']: entry for entry in historical['files']}
    for name, archive in overrides.items():
        assert name in historical_files, name
        assert archive.startswith('docs/recovered/') and '..' not in Path(archive).parts, archive
    for entry in historical['files']:
        path = ROOT / overrides.get(entry['path'], entry['path'])
        assert sha(path) == entry['sha256'], f'Changed historical source: {path}'
    for entry in current['files']:
        assert sha(ROOT / entry['path']) == entry['sha256'], f'Changed current source: {entry["path"]}'
    for name in current['removed_sources']:
        assert not (ROOT / name).exists(), f'Removed module has returned: {name}'
    # These files contain no nested comments or comment markers in string literals.
    # Compare the unchanged text outside comments as an additional revision check.
    def without_comments(text):
        return re.sub(r'/\-.*?\-/|--[^\n]*', '', text, flags=re.S)
    for entry in current['comment_only_changes']:
        name = entry['path']
        old = ROOT / overrides[name]
        new = ROOT / name
        assert sha(old) == entry['original_sha256']
        assert sha(new) == entry['current_sha256']
        assert without_comments(old.read_text()) == without_comments(new.read_text()), name
    return historical, current

def axiom_closures(path):
    text = path.read_text()
    assert 'sorryAx' not in text, f'Admitted proof in {path}'
    entries = re.findall(r"'([^']+)' depends on axioms: \[([^]]*)\]", text, re.S)
    return {name: sorted({x.strip() for x in axioms.split(',') if x.strip()})
            for name, axioms in entries}

def check_axioms(concrete, generic):
    expected_concrete = axiom_closures(ROOT / 'concrete/evidence/axioms.log')
    expected_generic = axiom_closures(ROOT / 'evidence/axioms.log')
    assert len(expected_concrete) == 22 and len(expected_generic) == 16
    assert axiom_closures(concrete) == expected_concrete, 'Concrete axiom dependencies changed'
    assert axiom_closures(generic) == expected_generic, 'Generic axiom dependencies changed'
    return len(expected_concrete), len(expected_generic)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--concrete-axioms', type=Path)
    parser.add_argument('--generic-axioms', type=Path)
    args = parser.parse_args()
    historical, current = check_sources()
    result = {'historical_files': len(historical['files']), 'current_files': len(current['files'])}
    if args.concrete_axioms or args.generic_axioms:
        assert args.concrete_axioms and args.generic_axioms, 'Supply both axiom logs'
        concrete, generic = check_axioms(args.concrete_axioms, args.generic_axioms)
        result.update(concrete_axiom_closures=concrete, generic_axiom_closures=generic)
    print(json.dumps(result))
