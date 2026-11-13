#!/usr/bin/env python3
"""Add an inspectable source snapshot to the local, unpublished documentation."""
import hashlib
import html
import json
import os
import re
from pathlib import Path

DOC = Path(__file__).resolve().parents[1]
ROOT = DOC.parents[1] / "Examples/HashCommitment"
SITE = Path(os.environ.get('BLUEPRINT_SITE', str(DOC.parent / '_out/site/html-multi')))
assert (SITE / 'index.html').is_file(), 'Build VersoBlueprint first.'
files = [ROOT / 'README.md']
files += [p for p in ROOT.glob('*') if p.is_file() and
          (p.suffix in {'.json', '.toml', '.lock'} or p.name == 'lean-toolchain')]
def source_files(root):
    # Prune build trees before traversing them, rather than filtering afterwards.
    for directory, directories, names in os.walk(root):
        directories[:] = sorted(name for name in directories if name not in {
            '.lake', '_out', 'target', '__pycache__', '.git', 'vendor'})
        for name in sorted(names):
            yield Path(directory) / name

for folder in ('rust', 'lean', 'scripts', 'evidence', 'patches'):
    for path in source_files(ROOT / folder):
        if path.suffix == '.log' and path.name not in {
            'axioms.log', 'blueprint-axioms.log', 'extraction.log', 'full-check.log',
            'lean-build.log', 'rust-tests.log'
        }:
            continue
        if path.suffix in {'.lean', '.rs', '.md', '.sh', '.py', '.json', '.toml', '.lock', '.log', '.patch'}:
            files.append(path)
# Documentation lives outside the independent proof package.
files += [p for p in source_files(DOC) if p.suffix in {'.lean', '.md', '.py'}]
manifest = []
for path in sorted(set(files)):
    relative = path.relative_to(ROOT) if path.is_relative_to(ROOT) else Path('blueprint') / path.relative_to(DOC)
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    target = SITE / 'source/HashCommitment' / relative
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
        f'<nav><a href="{"../" * (len(relative.parts) + 1)}index.html">Blueprint</a> · '
        f'<a href="{html.escape(target.name, quote=True)}">Raw source</a></nav>'
        f'<h1>{title}</h1><p>SHA-256: {digest}</p><pre>{lines}</pre></html>')
    manifest.append({'path': str(relative), 'sha256': digest})
(SITE / 'source/HashCommitment/manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(f'Prepared {len(manifest)} HashCommitment source files. Nothing was published.')

# Resolve only this chapter's links; the historical chapters retain their own rules.
DECL = re.compile(r'^\s*(?:@\[[^]]*\]\s*)*(?:(?:private|protected|noncomputable|partial|unsafe)\s+)*(?:theorem|def|abbrev|structure|class|inductive)\s+([^\s:(]+)')

def source_link(match):
    tag = match.group(0)
    href = html.unescape(re.search(r'href="([^"]+)"', tag)[1])
    base = href.split('#', 1)[0]
    if not base.startswith('source/HashCommitment/'):
        return tag
    name = html.unescape(re.search(r'data-declaration="([^"]+)"', tag)[1])
    source = SITE / base.removesuffix('.html')
    candidates = [i for i, line in enumerate(source.read_text().splitlines(), 1)
                  if (found := DECL.search(line)) and
                  (name == found[1] or name.endswith('.' + found[1]))]
    assert len(candidates) == 1, (source, name, candidates)
    return tag.replace(f'href="{href}"', f'href="{base}#L{candidates[0]}"')

for page in SITE.rglob('*.html'):
    text = page.read_text()
    updated = re.sub(r'<a\b[^>]*class="bp_source_link"[^>]*>', source_link, text)
    if updated != text:
        page.write_text(updated)
