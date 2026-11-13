#!/usr/bin/env python3
"""Export the shared book, keeping full source/evidence in the repository."""
from pathlib import Path
import argparse, html, json, re, shutil
from chapter_registry import expected_panels
DOC = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--repository-revision', required=True)
args = parser.parse_args()
assert re.fullmatch(r'[0-9a-f]{40}|main', args.repository_revision)
repo = 'https://github.com/a-dangelo/crypto-dh-poc'
blob = f'{repo}/blob/{args.repository_revision}/'
source = DOC / '_out/site/html-multi'
dest = DOC / '_out/site/pages-public'
assert (source / 'index.html').is_file()
shutil.rmtree(dest, ignore_errors=True)
shutil.copytree(source, dest, ignore=shutil.ignore_patterns('source', 'source-snapshot.zip'))
def repository_url(match):
    path = html.unescape(match.group(0)).removeprefix('source/')
    example, path = path.split('/', 1)
    path = re.sub(r'\.html(?=#|$)', '', path)
    path, sep, fragment = path.partition('#')
    if path == 'source-snapshot.zip':
        return blob.replace('/blob/', '/tree/') + f'Examples/{example}'
    mapped = {'manifest.json':f'docs/{example}/current-source-manifest.json' if example == 'DH' else f'Examples/{example}/README.md',
              'line-counts.json':f'docs/{example}/source-line-counts.json',
              'documentation-manifest.json':f'docs/{example}/README.md',
              'source-snapshot.zip':f'Examples/{example}'}
    if path.startswith('historical/'):
        old = path.removeprefix('historical/')
        overrides = json.loads((DOC / 'DH/current-source-manifest.json').read_text())['historical_path_overrides']
        target = {'manifest.json':'docs/DH/source-manifest.json','line-counts.json':'docs/DH/source-line-counts.json'}.get(old, 'Examples/DH/' + overrides.get(old,old))
    elif path.startswith('blueprint/'):
        target = f'docs/{example}/' + path.removeprefix('blueprint/')
    else:
        target = mapped.get(path, f'Examples/{example}/{path}')
    return blob + target + sep + fragment

def rewrite(text):
    text = re.sub(r'(<a\b[^>]*href="source/DH/source-snapshot\.zip"[^>]*>)Download source(</a>)', r'\1Browse source\2', text)
    text = re.sub(r'(?<![\w:/])source/(?:DH|Schnorr|HashCommitment)/[A-Za-z0-9_./#-]+', repository_url, text)
    text = text.replace(str(DOC.parent) + '/', '')
    return re.sub(r'\b(href|src)="/(?!/)', r'\1="', text)
def walk(value):
    if isinstance(value,str):return rewrite(value)
    if isinstance(value,list):return [walk(v) for v in value]
    if isinstance(value,dict):return {k:walk(v) for k,v in value.items()}
    return value
for path in dest.rglob('*'):
    if not path.is_file(): continue
    if path.suffix == '.json':path.write_text(json.dumps(walk(json.loads(path.read_text())), ensure_ascii=False) + '\n')
    elif path.suffix in {'.html','.js','.mjs'}:
        text = rewrite(path.read_text())
        if path.suffix == '.html': text = text.replace('</head>', '<meta name="robots" content="noindex, nofollow"></head>')
        path.write_text(text)
    assert path.suffix not in {'.lean','.rs','.log','.zip','.llbc'}
(dest / '.nojekyll').write_text('')
print(dest)
# Validate the publication boundary and all local navigation after rewriting.
import sys
from urllib.parse import urlsplit, unquote
sys.path.insert(0, str(DOC / 'DH/scripts'))
from site_checks import Page, VCVIO_SOURCE_URL
pages = {}
for path in dest.rglob('*.html'):
    parsed = Page(); parsed.feed(path.read_text()); pages[path.resolve()] = parsed
links = cards = hovers = 0
for path, page in pages.items():
    for link in page.links:
        url = urlsplit(link)
        if url.scheme or url.netloc: continue
        assert not url.path.startswith('/'), (path, link)
        target = (path.parent / page.base / unquote(url.path)).resolve() if (url.path or page.base) else path
        if target.is_dir():target /= 'index.html'
        assert target.is_file(), (path, link)
        if url.fragment and target in pages: assert unquote(url.fragment) in pages[target].ids, (path, link)
        links += 1
    assert page.cards == page.open_cards == len(page.blocks) == len(page.card_sources)
    for (code, hover), link in zip(page.blocks, page.card_sources):
        target = link.split('#')[0]
        if target.startswith(blob):target = DOC.parent / target.removeprefix(blob)
        elif target.startswith(VCVIO_SOURCE_URL):target = DOC.parent / 'Examples/DH/vendor/VCVio' / target.removeprefix(VCVIO_SOURCE_URL)
        else:raise AssertionError(link)
        assert code in target.read_text(), link
        assert hover > 0, link
        hovers += hover
    cards += page.cards
assert cards == expected_panels(), cards
assert not (dest / 'source').exists()
for path in dest.rglob('*'):
    if path.is_file():
        assert not path.is_symlink()
        assert path.suffix not in {'.lean','.rs','.log','.zip','.tar','.gz','.tgz','.llbc'}
print(json.dumps({'status':'passed','html_pages':len(pages),'links':links,'declaration_panels':cards,'source_hovers':hovers,'whole_source_published':False}))
