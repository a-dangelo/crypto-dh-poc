#!/usr/bin/env python3
"""Optional unpublished browser QA; requires Playwright and Chromium."""
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import threading
from playwright.sync_api import sync_playwright

DOC = Path(__file__).resolve().parents[1]
SITE = DOC / '_out/site/html-multi'
OUT = DOC / '_out/qa'
OUT.mkdir(parents=True, exist_ok=True)
assert (SITE / 'index.html').exists(), 'Build the site first.'

class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass

server = ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(SITE)))
threading.Thread(target=server.serve_forever, daemon=True).start()
base = f'http://127.0.0.1:{server.server_port}'
pages = [SITE / 'index.html']
pages.extend(p for p in SITE.rglob('*.html')
             if 'source' not in p.relative_to(SITE).parts and p not in pages
)
results = []
try:
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path='/usr/bin/chromium', headless=True)
        for label, width, height in [('desktop', 1440, 1000), ('narrow', 390, 844)]:
            page = browser.new_page(viewport={'width': width, 'height': height}, device_scale_factor=1)
            errors = []
            page.on('pageerror', lambda error: errors.append(str(error)))
            for i, path in enumerate(pages):
                relative = path.relative_to(SITE).as_posix()
                response = page.goto(f'{base}/{relative}', wait_until='networkidle')
                assert response and response.ok, relative
                page.wait_for_timeout(500)
                assert page.locator('.katex-error').count() == 0, relative
                if page.locator('.bp_graph_canvas').count():
                    page.locator('.bp_graph_canvas svg').first.wait_for(timeout=15000)
                metrics = page.evaluate('''() => ({
                    width: innerWidth, scrollWidth: document.documentElement.scrollWidth,
                    panels: document.querySelectorAll('.bp_declaration_card').length,
                    math: document.querySelectorAll('.katex').length,
                    graphSvg: document.querySelectorAll('.bp_graph_canvas svg').length
                })''')
                assert metrics['scrollWidth'] <= width + 2, (label, relative, metrics)
                if label == 'desktop' and page.locator('.bp_declaration_card [data-verso-hover]').count():
                    page.locator('.bp_declaration_card [data-verso-hover]').first.hover()
                    page.locator('[data-tippy-root]').first.wait_for(state='visible', timeout=10000)
                    assert page.locator('[data-tippy-root]').first.inner_text().strip(), relative
                    page.mouse.move(0, 0)
                if i < 2:
                    page.screenshot(path=str(OUT / f'{label}-{i}.png'), full_page=False)
                results.append({'viewport': label, 'page': relative, **metrics})
            assert not errors, errors
            page.close()
        browser.close()
finally:
    server.shutdown()
(OUT / 'browser-qa.json').write_text(json.dumps(results, indent=2) + '\n')
print(f'Checked {len(results)} page/viewport combinations. Screenshots remain local in {OUT}.')
