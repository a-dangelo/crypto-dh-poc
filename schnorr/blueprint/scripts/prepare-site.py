#!/usr/bin/env python3
"""Add an inspectable source snapshot to the local, unpublished documentation."""
import hashlib
import html
import json
from pathlib import Path

DOC = Path(__file__).resolve().parents[1]
ROOT = DOC.parent
SITE = DOC / '_out/site/html-multi'
assert (SITE / 'index.html').is_file(), 'Build VersoBlueprint first.'
files = [ROOT / 'README.md']
for folder in ('rust', 'lean', 'scripts', 'evidence', 'blueprint'):
    for path in (ROOT / folder).rglob('*'):
        relative = path.relative_to(ROOT)
        if any(part in {'.lake', '_out', 'target', '__pycache__'} for part in relative.parts):
            continue
        if path.suffix == '.log' and path.name not in {
            'axioms.log', 'blueprint-axioms.log', 'extraction.log', 'full-check.log',
            'lean-build.log', 'ristretto-tests.log', 'rust-tests.log'
        }:
            continue
        if path.is_file() and path.suffix in {'.lean', '.rs', '.md', '.sh', '.py', '.json', '.toml', '.lock', '.log'}:
            files.append(path)
manifest = []
for path in sorted(set(files)):
    relative = path.relative_to(ROOT)
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    target = SITE / 'source' / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    title = html.escape(str(relative))
    lines = '\n'.join(f'<span id="L{i}"><a href="#L{i}">{i:4}</a> {html.escape(line)}</span>'
                      for i, line in enumerate(data.decode().splitlines(), 1))
    Path(str(target) + '.html').write_text(
        '<!doctype html><html lang="en"><meta charset="utf-8">'
        '<meta name="viewport" content="width=device-width, initial-scale=1">'
        f'<title>{title}</title><style>body{{margin:2rem;font-family:system-ui}}'
        'pre{overflow:auto;line-height:1.5}pre span{display:block}a{color:#275a8a}</style>'
        f'<nav><a href="{"../" * len(relative.parts)}index.html">Blueprint</a> · '
        f'<a href="{html.escape(target.name, quote=True)}">Raw source</a></nav>'
        f'<h1>{title}</h1><p>SHA-256: {digest}</p><pre>{lines}</pre></html>')
    manifest.append({'path': str(relative), 'sha256': digest})
(SITE / 'source/manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(f'Prepared {len(manifest)} Schnorr source files. Nothing was published.')
