#!/usr/bin/env python3
"""Export the intended Blueprint content without publishing the private source tree."""
from pathlib import Path
from urllib.parse import urlparse, unquote
import argparse, hashlib, html, json, re, shutil
from site_checks import Page, declaration_source, EXPECTED_PAIRS

DOC = Path(__file__).resolve().parents[1]
ROOT = DOC.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--repository-revision', required=True,
                    help='Exact private repository commit; main is accepted for local preview only.')
args = parser.parse_args()
assert re.fullmatch(r'[0-9a-f]{40}|main',args.repository_revision)
repository = 'https://github.com/a-dangelo/crypto-dh-poc'
blob = f'{repository}/blob/{args.repository_revision}/'
source = DOC/'_out/site/html-multi'
destination = DOC/'_out/site/pages-public'
assert (source/'index.html').is_file(), 'Run scripts/build.sh first'
shutil.rmtree(destination,ignore_errors=True)
shutil.copytree(source,destination,ignore=shutil.ignore_patterns('source','source-snapshot.zip'))

# Keep only the authored declaration excerpts and their native hover/graph data.
# Full files and evidence stay in the private repository.
def private_url(path):
    path = html.unescape(path)
    path = path.removeprefix('source/')
    path = re.sub(r'\.(lean|rs)\.html(?=#|$)',r'.\1',path)
    path, separator, fragment = path.partition('#')
    path = {'README.md':'README.md',
            'manifest.json':'blueprint/current-source-manifest.json',
            'line-counts.json':'blueprint/source-line-counts.json',
            'documentation-manifest.json':'blueprint/README.md'}.get(path,path)
    if path.startswith('historical/'):
        historical = path.removeprefix('historical/')
        current = json.loads((DOC/'current-source-manifest.json').read_text())
        path = {'manifest.json':'blueprint/source-manifest.json',
                'line-counts.json':'blueprint/source-line-counts.json'}.get(
                    historical, current['historical_path_overrides'].get(historical, historical))
    return blob+path+separator+fragment

def rewrite(text):
    text = text.replace(str(ROOT)+"/", "")
    text = re.sub(r'<a\b[^>]*href="source-snapshot\.zip"[^>]*>.*?</a>',
                  f'<a href="{repository}">Private source repository</a>',text,flags=re.S)
    text = re.sub(r'(?<![\w:/])source/([A-Za-z0-9_./#-]+)',
                  lambda m:private_url(m.group(0)),text)
    text = text.replace('source-snapshot.zip',repository)
    # Verso pages use a relative <base>; root-relative attributes must not escape
    # a GitHub project Pages prefix such as /crypto-dh-poc/.
    text = re.sub(r'\b(href|src)="/(?!/)',r'\1="',text)
    return text

def walk(value):
    if isinstance(value,str):return rewrite(value)
    if isinstance(value,list):return [walk(x) for x in value]
    if isinstance(value,dict):return {k:walk(v) for k,v in value.items()}
    return value

for path in destination.rglob('*'):
    if not path.is_file():continue
    assert not path.is_symlink(),path
    if path.suffix=='.json':
        path.write_text(json.dumps(walk(json.loads(path.read_text())),ensure_ascii=False,separators=(',',':'))+'\n')
    elif path.suffix in {'.html','.js','.mjs'}:
        text=rewrite(path.read_text())
        if path.suffix=='.html':
            text=text.replace('</head>','<meta name="robots" content="noindex, nofollow"></head>')
        path.write_text(text)
(destination/'.nojekyll').write_text('')

# Verify public content, fragment links and declaration fidelity independently.
for p in destination.rglob('*'):
    assert not p.is_symlink(),p
    if p.is_file():
        assert p.suffix not in {'.lean','.rs','.log','.zip','.tar','.gz','.tgz','.llbc'},p
        assert 'source' not in p.relative_to(destination).parts,p
pages={}
for p in destination.rglob('*.html'):
    q=Page();q.feed(p.read_text());pages[p.resolve()]=q
errors=[];links=0;hovers=0
for p,q in pages.items():
    text=p.read_text()
    assert 'name="robots" content="noindex, nofollow"' in text,p
    assert 'source-snapshot.zip' not in text,p
    for href in q.links:
        u=urlparse(href)
        if u.scheme or u.netloc:continue
        assert not u.path.startswith('/'),(p,href)
        target=(p.parent/q.base/unquote(u.path)).resolve() if (u.path or q.base) else p
        if target.is_dir():target/='index.html'
        if not target.is_file():errors.append(f'{p.name}: {href}')
        elif u.fragment and target in pages and unquote(u.fragment) not in pages[target].ids:
            errors.append(f'{p.name}: {href}')
        links+=1
    if q.cards:
        assert q.cards==q.open_cards==len(q.blocks)==len(q.card_sources),p
        for (code,n),href in zip(q.blocks,q.card_sources):
            path=declaration_source(href,ROOT,private_blob=blob)
            assert code in path.read_text(),path
            assert n>0,path
            hovers+=n
assert not errors,'\n'.join(errors)
assert sum(q.cards for q in pages.values())==sum(q.pairs for q in pages.values())==EXPECTED_PAIRS
assert not (destination/'source').exists()
assert not (destination/'source-snapshot.zip').exists()
print(json.dumps({'status':'passed','output':str(destination),
 'html_pages':len(pages),'local_links':links,'declaration_pairs':EXPECTED_PAIRS,'source_hovers':hovers,
 'files':sum(p.is_file() for p in destination.rglob('*')),
 'repository_revision':args.repository_revision,'whole_source_published':False}))
