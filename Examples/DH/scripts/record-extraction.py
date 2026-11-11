#!/usr/bin/env python3
"""Bind completed extraction evidence to the exact copied inputs and outputs."""
import hashlib
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda:f.read(1048576),b''): h.update(block)
    return h.hexdigest()
source=root/'concrete/rust/poc_dh.rs'
copy=root/'vendor/dalek-extraction/curve25519-dalek/src/poc_dh.rs'
if source.read_bytes()!=copy.read_bytes(): raise SystemExit('Extracted wrapper input does not match current source')
inputs={'concrete/rust/poc_dh.rs':sha(source)}
patches={str(p.relative_to(root/'vendor/dalek-proof')):sha(p) for p in sorted((root/'vendor/dalek-proof/curve25519-dalek/translation-patches').glob('*.patch'))}
outputs={}
for rel in ['concrete/evidence/curve25519_dalek.llbc',
 'concrete/evidence/generated/Curve25519Dalek/Funs.lean',
 'concrete/evidence/generated/Curve25519Dalek/Types.lean']:
    outputs[rel]=sha(root/rel)
record={'inputs':inputs,'patches':patches,'outputs':outputs,
 'dalek_revision':'95b5831c63ff1c5f6287bd3a77569412a9afdbfb',
 'aeneas_release':'nightly-2026.10.30-de16f3c'}
(root/'concrete/evidence/extraction-inputs.json').write_text(json.dumps(record,indent=2)+'\n')
