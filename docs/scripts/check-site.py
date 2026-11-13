#!/usr/bin/env python3
"""Validate the one-book navigation, exact declaration excerpts, and source snapshots."""
from pathlib import Path
from urllib.parse import unquote, urlsplit
import hashlib, json, sys
from chapter_registry import CHAPTERS, TITLES, expected_panels
DOC = Path(__file__).resolve().parents[1]
REPO = DOC.parent
SITE = DOC / '_out/site/html-multi'
sys.path.insert(0, str(DOC / 'DH/scripts'))
from site_checks import Page, VCVIO_SOURCE_URL
pages = {}
for path in SITE.rglob('*.html'):
    parser = Page(); parser.feed(path.read_text()); pages[path.resolve()] = parser
assert (SITE / 'index.html').resolve() in pages
links = cards = hovers = 0
for path, page in pages.items():
    for link in page.links:
        url = urlsplit(link)
        if url.scheme or url.netloc: continue
        target = ((SITE / unquote(url.path).lstrip('/')) if url.path.startswith('/') else
                  path.parent / page.base / unquote(url.path) if (url.path or page.base) else path).resolve()
        if target.is_dir(): target /= 'index.html'
        assert target.is_file(), (path, link)
        if url.fragment and target in pages:
            assert unquote(url.fragment) in pages[target].ids, (path, link)
        links += 1
    assert page.cards == page.open_cards == len(page.blocks) == len(page.card_sources), path
    for (source, hover), link in zip(page.blocks, page.card_sources):
        file = link.split('#')[0]
        if file.startswith(VCVIO_SOURCE_URL):
            target = REPO / 'Examples/DH/vendor/VCVio' / file.removeprefix(VCVIO_SOURCE_URL)
        else:
            assert file.startswith(tuple(f'source/{chapter}/' for chapter in CHAPTERS)), link
            target = SITE / file.removesuffix('.html')
        assert source in target.read_text(), ('Declaration differs from source', link)
        assert hover > 0, ('Missing declaration hovers', link)
        hovers += hover
    cards += page.cards
for example in CHAPTERS:
    manifest = json.loads((SITE / f'source/{example}/manifest.json').read_text())
    entries = manifest['files'] if isinstance(manifest, dict) else manifest
    for entry in entries:
        assert hashlib.sha256((SITE / f'source/{example}' / entry['path']).read_bytes()).hexdigest() == entry['sha256']
text = '\n'.join(p.read_text() for p in pages if 'source' not in p.relative_to(SITE).parts)
assert all(title in text for title in TITLES)
assert 'katex-error' not in text
assert cards == expected_panels(), cards
assert 'tactic-state' in text
print(json.dumps({'status':'passed', 'pages':len(pages), 'links':links, 'declaration_panels':cards, 'source_hovers':hovers}))
