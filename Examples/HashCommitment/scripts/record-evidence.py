#!/usr/bin/env python3
"""Record exact local inputs and outputs; a manifest is provenance, not a proof."""
import hashlib, json, pathlib, subprocess
root = pathlib.Path(__file__).resolve().parents[1]
def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()
def revision(p):
    return subprocess.check_output(['git', '-C', str(p), 'rev-parse', 'HEAD'], text=True).strip()
files = {}
for directory in ['rust', 'lean/HashCommitment', 'scripts', 'patches', 'evidence']:
    for p in sorted((root / directory).rglob('*')):
        rel = p.relative_to(root)
        if not p.is_file() or any(x in rel.parts for x in ['target', '__pycache__']): continue
        if p.name in {'manifest.json', 'shared-audit.json', 'blueprint-axioms.log'}: continue
        files[str(rel)] = digest(p)
for name in ['lean/lean-toolchain', 'lean/lakefile.lean', 'lean/lake-manifest.json', 'lean/AxiomAudit.lean', 'lean/HashCommitment.lean', 'vendor/aeneas/.hash-commitment-build.json']:
    p = root / name
    if p.exists(): files[name] = digest(p)
manifest = {'schema': 1, 'description': 'SHA-256 provenance of local check inputs and outputs; consult logs for outcomes.',
            'aeneas_base': revision(root/'vendor/aeneas'), 'charon': revision(root/'vendor/aeneas/charon'),
            'vcvio': revision(root/'vendor/VCVio'), 'files': files}
(root/'evidence/manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
