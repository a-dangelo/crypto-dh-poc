"""Shared HTML parser for private and public Blueprint checks."""
from html.parser import HTMLParser
VOID={'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}
class Page(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.links=[];self.ids=set();self.base='';self.cards=0;self.open_cards=0
        self.pairs=0;self.blocks=[];self.parts=None;self.hidden=0;self.hovers=0;self.card_depth=0
        self.card_sources=[];self.prose_first=True
    def handle_starttag(self,tag,attrs):
        a=dict(attrs);classes=set(a.get('class','').split())
        if tag=='base':self.base=a.get('href','')
        if 'id' in a:self.ids.add(a['id'])
        if tag=='a' and 'href' in a:self.links.append(a['href'])
        if 'bp_math_code' in classes:self.pairs+=1
        if tag=='details' and 'bp_declaration_card' in classes:
            self.cards+=1;self.open_cards+=int('open' in a);self.card_depth=1
        elif self.card_depth and tag not in VOID:self.card_depth+=1
        if self.card_depth and 'bp_source_link' in classes:self.card_sources.append(a['href'])
        if self.hidden:
            if tag not in VOID:self.hidden+=1
            return
        if self.card_depth and tag=='code' and {'hl','lean','block'}<=classes:
            self.parts=[];self.hovers=0
        if self.parts is not None:
            if {'tactic-state','hover-info'} & classes:self.hidden=1
            elif 'data-verso-hover' in a:self.hovers+=1
    def handle_data(self,data):
        if self.parts is not None and not self.hidden:self.parts.append(data)
    def handle_endtag(self,tag):
        if self.hidden:self.hidden-=1
        elif tag=='code' and self.parts is not None:
            self.blocks.append((''.join(self.parts).strip(),self.hovers));self.parts=None
        if self.card_depth:self.card_depth-=1


VCVIO_SOURCE_URL = 'https://github.com/Verified-zkEVM/VCVio/blob/88efe9715a9fa9e7d89635c38cf70259836766c2/'
EXPECTED_PAIRS = 33

def declaration_source(link, repository_root, *, source_directory=None, private_blob=None):
    """Resolve only the pinned dependency or an explicitly rendered local declaration."""
    from pathlib import Path
    from urllib.parse import unquote
    path = unquote(link.split('#', 1)[0])
    if path.startswith(VCVIO_SOURCE_URL):
        return repository_root / 'vendor/VCVio' / path.removeprefix(VCVIO_SOURCE_URL)
    if private_blob and path.startswith(private_blob):
        return repository_root / path.removeprefix(private_blob)
    if path.startswith('source/'):
        relative = path.removeprefix('source/').removesuffix('.html')
        assert '..' not in Path(relative).parts, link
        return (source_directory if source_directory is not None else repository_root) / relative
    raise AssertionError(f'Unexpected declaration source: {link}')
