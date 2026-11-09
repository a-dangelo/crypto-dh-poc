#!/usr/bin/env python3
"""Copy generated wrapper declarations exactly and compare all retained backend declarations."""
from pathlib import Path
import hashlib
import json
import re
import sys

root = Path(__file__).resolve().parents[1]
new = root / 'concrete/evidence/generated/Curve25519Dalek'
old = root / 'vendor/dalek-proof/curve25519-dalek/lean/Curve25519Dalek'

def chunks(text):
    result = {}
    for block in re.split(r'(?=^/--)', text, flags=re.M)[1:]:
        # These generated comments precede exactly one declaration.
        header = block.split('Source:', 1)[0].strip()
        block = re.sub(r'\nend Curve25519Dalek\s*$', '\n', block)
        result[header] = block
    return result

def normalize(text):
    text = re.sub(r'/\-.*?\-/', '', text, flags=re.S)
    return text.strip()

summary = {}
selected = []
for filename in ['Types.lean', 'Funs.lean']:
    a = chunks((old / filename).read_text())
    b = chunks((new / filename).read_text())
    # Match stable Rust declaration headers, independent of diagnostic source paths.
    def key(header):
        return re.sub(r'\s+', ' ', header).strip()
    a = {key(k): v for k, v in a.items()}
    b = {key(k): v for k, v in b.items()}
    missing = sorted(set(a) - set(b))
    changed = [k for k in a.keys() & b.keys() if normalize(a[k]) != normalize(b[k])]
    extra = sorted(set(b) - set(a))
    summary[filename] = {'upstream_blocks': len(a), 'generated_blocks': len(b),
        'missing': missing, 'changed': changed, 'extra': extra}
    for k, block in b.items():
        if '::poc_dh::' in k:
            selected.append(block)
    if missing or changed or any('::poc_dh::' not in k for k in extra):
        # Record the differences and stop before writing an adapter.
        (root/'concrete/evidence/linkage-comparison.json').write_text(json.dumps(summary, indent=2)+'\n')
        raise SystemExit(f'Backend alignment failed for {filename}: {len(missing)} missing, {len(changed)} changed, {len(extra)} extra')

out = '''-- Automatically sliced from the actual full Aeneas output. Do not edit.
-- The script checks all unchanged backend declarations against the pinned proof source.
import Curve25519Dalek.Funs
open Aeneas Aeneas.Std Result ControlFlow Error
noncomputable section
namespace Curve25519Dalek
\n''' + '\n'.join(selected) + '\nend Curve25519Dalek\n'
p = root / 'concrete/Concrete/GeneratedAdapter.lean'
if "--check" in sys.argv:
    if not p.exists() or p.read_text() != out:
        raise SystemExit("Generated adapter differs from the checked source")
else:
    p.write_text(out)
summary['adapter_sha256'] = hashlib.sha256(out.encode()).hexdigest()
summary['adapter_lines'] = len(out.splitlines())
(root/'concrete/evidence/linkage-comparison.json').write_text(json.dumps(summary, indent=2)+'\n')
print(f'Generated {p.name}: {len(out.splitlines())} lines. All original declarations unchanged.')
