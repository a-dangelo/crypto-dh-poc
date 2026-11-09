#!/usr/bin/env python3
"""Validate links, source hashes, paired declarations, and retained source hovers."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse, unquote
import hashlib,json,re
DOC=Path(__file__).resolve().parents[1]
ROOT=DOC/'_out/site/html-multi'
from site_checks import Page

pages={}
for p in ROOT.rglob('*.html'):
    parser=Page();parser.feed(p.read_text());pages[p]=parser
errors=[];links=0
for p,parser in pages.items():
    for link in parser.links:
        u=urlparse(link)
        if u.scheme or u.netloc:continue
        target=((ROOT/unquote(u.path).lstrip('/')) if u.path.startswith('/') else
                (p.parent/parser.base/unquote(u.path)) if (u.path or parser.base) else p).resolve()
        if target.is_dir():target/='index.html'
        if not target.is_file():errors.append(f'{p.relative_to(ROOT)}: missing {link}')
        elif u.fragment and target in pages and unquote(u.fragment) not in pages[target].ids:
            errors.append(f'{p.relative_to(ROOT)}: missing anchor {link}')
        links+=1
    if parser.cards:
        assert parser.cards==parser.open_cards==len(parser.blocks)==len(parser.card_sources),(p,parser.cards,len(parser.blocks))
        for (source,hovers),link in zip(parser.blocks,parser.card_sources):
            path=(ROOT/urlparse(link).path).with_suffix('')
            assert source in path.read_text(),f'Rendered source differs from file: {link}'
            assert hovers>0,f'Missing source hovers: {link}'
for name in ['manifest.json','documentation-manifest.json']:
    data=json.loads((ROOT/'source'/name).read_text())
    for e in data['files']:
        if hashlib.sha256((ROOT/'source'/e['path']).read_bytes()).hexdigest()!=e['sha256']:
            errors.append(f'Changed source snapshot: {e["path"]}')
allhtml='\n'.join(p.read_text() for p in pages if '/source/' not in str(p))
assert 'class="katex-error"' not in allhtml,'Invalid mathematics'
cards=sum(p.cards for p in pages.values());pairs=sum(p.pairs for p in pages.values())
assert cards==pairs==13,(cards,pairs)
assert allhtml.count('<span class="tactic-state">')>0,'Missing tactic-state data'
# The DOM order, not just visual CSS, places prose before Lean.
for p in pages:
    if '/source/' not in str(p):
        for m in re.finditer(r'<div class="bp_math_code">',p.read_text()):
            assert p.read_text()[m.end():].lstrip().startswith('<div class="bp_pair_prose">')
assert not errors,'\n'.join(errors)
print(json.dumps({'status':'passed','html_pages':len(pages),'links':links,'pairs':pairs,
                  'core_hashes':len(json.loads((ROOT/'source/manifest.json').read_text())['files']),
                  'source_hovers':sum(h for p in pages.values() for _,h in p.blocks)}))
