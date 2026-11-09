#!/usr/bin/env python3
"""Prepare current review sources and preserve the historical evidence separately."""
from pathlib import Path
import hashlib, html, json, re, shutil, subprocess, zipfile
from site_checks import declaration_source
from proof_replay import check_replay
import argparse

DOC = Path(__file__).resolve().parents[1]
ROOT = DOC.parent
SITE = DOC / '_out/site/html-multi'

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--replay-directory', required=True, type=Path)
replay_directory = parser.parse_args().replay_directory.resolve()

# Verify the current sources and the original snapshot independently.
import importlib.util
spec = importlib.util.spec_from_file_location('check_sources', DOC / 'scripts/check-sources.py')
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)
historical, manifest = checks.check_sources()
def snapshot_path(relative):
    return ROOT / manifest['historical_path_overrides'].get(str(relative), str(relative))

report = json.loads((ROOT / 'concrete/evidence/concrete-proof-report.json').read_text())
assert report['status'] == 'checked_end_to_end_standard_DDH_reduction'
required = {'DhConcrete.wideAdvantage_le_of_standardDDH',
            'DhConcrete.uniformWide_scalar_measureETVDist_le',
            'DhPoc.sampledDDHAdvantage_le_standard'}
assert required <= report['audited_declarations'].keys()
allowed = {'propext', 'Classical.choice', 'Quot.sound', 'RustAx.core', 'RustAx.subtle'}
for name, axioms in report['audited_declarations'].items():
    assert set(axioms) <= allowed, name
for name, entry in report['files'].items():
    assert hashlib.sha256(snapshot_path(name).read_bytes()).hexdigest() == entry['sha256'], name
# Bind the current source manifest to this build's successful commands and audits.
# The stored prose-only replay remains historical evidence, unchanged.
replay = check_replay(replay_directory)

assert (SITE/'index.html').exists()
xref = json.loads((SITE/'xref.json').read_text())
for entries in xref['Verso.Genre.Manual.section']['contents'].values():
    for entry in entries:
        if len(entry['data']['context']) > 2:
            continue
        page = SITE / entry['address'].lstrip('/') / 'index.html'
        if not page.is_file():
            continue
        content = page.read_text()
        anchor = html.escape(entry['id'], quote=True)
        if f'id="{anchor}"' not in content:
            assert '<main>' in content
            content = content.replace('<main>', f'<main><span id="{anchor}" class="page-top-anchor" aria-hidden="true"></span>', 1)
        page.write_text(content)

shutil.copyfile(DOC/'assets/review.css', SITE/'review.css')
for page in SITE.rglob('*.html'):
    content = page.read_text()
    if 'href="review.css"' not in content:
        content = content.replace('</head>', '<link rel="stylesheet" href="review.css"></head>')
    content = content.replace('height=device-height, width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1',
                              'width=device-width, initial-scale=1')
    def source_link(m):
        tag = m.group(0)
        href = html.unescape(re.search(r'href="([^"]+)"',tag)[1])
        name = html.unescape(re.search(r'data-declaration="([^"]+)"',tag)[1])
        base_href = href.split('#',1)[0]
        source_file = declaration_source(base_href, ROOT)
        lines = source_file.read_text().splitlines()
        short = name.split('.')[-1]
        pattern = re.compile(r'^\s*(?:(?:private|protected|noncomputable|partial|unsafe)\s+)*(?:theorem|def|abbrev|structure|class|inductive)\s+([^\s:(]+)')
        candidates = [i+1 for i,line in enumerate(lines)
                      if (hit := pattern.search(line)) and hit[1].split('.')[-1] == short]
        assert len(candidates) == 1, (source_file,name,candidates)
        return tag.replace(f'href="{href}"',f'href="{base_href}#L{candidates[0]}"')
    content = re.sub(r'<a\b[^>]*class="bp_source_link"[^>]*>',source_link,content)
    page.write_text(content)

shutil.rmtree(SITE/'source',ignore_errors=True)
for entry in manifest['files']:
    rel=Path(entry['path']); target=SITE/'source'/rel
    target.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(ROOT/rel,target)
    if rel.suffix in {'.lean','.rs'}:
        lines=target.read_text().splitlines()
        body='\n'.join(f'<span class="source-line" id="L{i}"><a class="line-number" href="#L{i}">{i}</a>{html.escape(line)}</span>' for i,line in enumerate(lines,1))
        title=html.escape(str(rel))
        page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>'+title+'</title><link rel="stylesheet" href="/review.css"></head><body class="source-page"><nav><a href="/">Blueprint</a> · <a href="/source/'+str(rel)+'">Raw source</a></nav><h1>'+title+'</h1><p>SHA-256 '+entry['sha256']+'</p><pre>'+body+'</pre></body></html>'
        Path(str(target)+'.html').write_text(page)

# Retain actual current-run proof evidence only in the private source snapshot.
current_verification = SITE/'source/current-verification'
current_verification.mkdir(parents=True, exist_ok=True)
for name in ['replay.json', *replay['log_sha256']]:
    shutil.copyfile(replay_directory / name, current_verification / name)

(SITE/'source/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
# Preserve the recovered snapshot under a separate historical prefix.
for entry in historical['files']:
    target = SITE/'source/historical'/entry['path']
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(snapshot_path(entry['path']), target)
(SITE/'source/historical/manifest.json').write_text(json.dumps(historical, indent=2)+'\n')
shutil.copyfile(DOC/'source-line-counts.json', SITE/'source/historical/line-counts.json')
# Existing links to line counts describe the original snapshot explicitly.
shutil.copyfile(DOC/'source-line-counts.json', SITE/'source/line-counts.json')
# Persist editable documentation too. Keep its provenance separate from the original core.
docfiles = [p for p in DOC.rglob('*') if p.is_file() and
            not any(part in {'.git','.lake','_out','__pycache__'} for part in p.relative_to(DOC).parts)]
entries=[]
for p in sorted(docfiles):
    rel=Path('blueprint')/p.relative_to(DOC);target=SITE/'source'/rel
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target)
    entries.append({'path':str(rel),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
try:
    doccommit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=DOC,text=True,stderr=subprocess.DEVNULL).strip()
except subprocess.CalledProcessError:
    doccommit=None
docmanifest={'provenance':'Newly reconstructed and revised documentation; not recovered original Git history.',
             'historical_core_source_commit':historical['source_commit'],'documentation_commit':doccommit,'files':entries}
(SITE/'source/documentation-manifest.json').write_text(json.dumps(docmanifest,indent=2)+'\n')
with zipfile.ZipFile(SITE/'source-snapshot.zip','w',zipfile.ZIP_DEFLATED) as archive:
    for p in sorted((SITE/'source').rglob('*')):
        if p.is_file() and not p.name.endswith('.html'):
            archive.write(p,p.relative_to(SITE))
print(json.dumps({'core_hashes':len(manifest['files']),'documentation_files':len(entries)}))
