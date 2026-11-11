#!/usr/bin/env python3
"""Check local source links, dependency isolation, and retained declaration panels."""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

DOC = Path(__file__).resolve().parents[1]
SITE = DOC / '_out/site/html-multi'
for path in [DOC / 'lakefile.lean', *DOC.glob('*.lean'), *DOC.glob('SchnorrBlueprint/*.lean')]:
    text = path.read_text()
    assert 'DhBlueprint' not in text and 'DhPoc' not in text and 'Concrete.' not in text, path
assert '4943d3335ffa9221a39949e60836a8ad5dc2a456' in (DOC / 'lakefile.lean').read_text()
assert (SITE / 'index.html').exists(), 'No generated site.'

class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.declarations = set()
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'href' in attrs:
            self.links.append(attrs['href'])
        if 'data-declaration' in attrs:
            self.declarations.add(attrs['data-declaration'])

all_declarations = set()
for path in SITE.rglob('*.html'):
    parser = Links()
    parser.feed(path.read_text())
    all_declarations.update(parser.declarations)
    for link in parser.links:
        url = urlsplit(link)
        if url.scheme or url.netloc or not url.path:
            continue
        # Verso adds a root base URL, including on chapter pages.
        target = SITE / unquote(url.path.lstrip('/'))
        if not target.exists():
            target = path.parent / unquote(url.path)
        assert target.exists(), (path, link)
required = {'schnorr_core.messages', 'SchnorrProof.PrimitiveModel',
            'SchnorrProof.verify_accepts_iff', 'SchnorrProof.honest_complete',
            'SchnorrProof.special_soundness', 'SchnorrProof.rustTranscript',
            'SchnorrProof.rustTranscript_eq_encodedReal', 'SchnorrProof.perfect_hvzk'}
assert required <= all_declarations, required - all_declarations
print(f'Checked local links and {len(all_declarations)} declaration panels.')
