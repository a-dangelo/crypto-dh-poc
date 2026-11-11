#!/usr/bin/env python3
"""Record the source and tool identities after check.sh succeeds."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--mode', choices=('full', '--proof-only'), required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
def run(*command):
    return subprocess.check_output(command, cwd=root, text=True).strip()
files = []
for directory in ('rust', 'lean', 'scripts'):
    for path in (root / directory).rglob('*'):
        if any(part in {'.lake', 'target', '__pycache__'} for part in path.parts):
            continue
        if path.is_file() and path.suffix in {'.rs', '.lean', '.toml', '.lock', '.json', '.py', '.sh'}:
            files.append(path)
report = {
    'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
    'mode': args.mode,
    'platform': run('uname', '-sm'),
    'aeneas': run(str(root / 'vendor/aeneas/aeneas'), '-version'),
    'lean_toolchain': (root / 'lean/lean-toolchain').read_text().strip(),
    'vcvio_revision': run('git', '-C', str(root / 'vendor/VCVio'), 'rev-parse', 'HEAD'),
    'rustc': run('rustc', '--version') if args.mode == 'full' else None,
    'checked': ['Lean build', 'strict endpoint axiom audit', 'no DH imports'],
    'claim': 'Conditional protocol refinement, special soundness and perfect honest-verifier zero knowledge with ideal scalar randomness; exact runtime RNG interpretation is a separate functional theorem.',
    'not_claimed': ['concrete arithmetic verification', 'runtime RNG distribution', 'wire parser correctness', 'compiled machine-code correctness', 'side-channel security', 'Fiat-Shamir signature security'],
    'sha256': {str(path.relative_to(root)): sha(path) for path in sorted(files)},
}
if args.mode == 'full':
    report['checked'] += ['Rust core tests', 'Ristretto example tests', 'fresh extraction exactly matches committed Lean']
    report['llbc_sha256'] = sha(root / 'evidence/schnorr_core.llbc')
else:
    report['not_repeated'] = ['Rust tests', 'Charon/Aeneas extraction comparison']
(root / 'evidence/verification.json').write_text(json.dumps(report, indent=2) + '\n')
print('Recorded Schnorr verification evidence.')
