#!/usr/bin/env python3
"""Check the published book under its GitHub Pages prefix; requires Playwright."""
import argparse
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import shutil
import tempfile
import threading
from urllib.parse import urlsplit

DOC = Path(__file__).resolve().parents[1]
PREFIX = 'crypto-dh-poc'
SCREENSHOTS = {
    'index.html': 'home',
    'DH-session-in-Rust/index.html': 'dh',
    'Interactive-Schnorr-in-Rust/index.html': 'schnorr',
    'Interactive-Schnorr-in-Rust/Sampled-transcripts-and-perfect-HVZK/index.html': 'schnorr-hvzk',
    'Dependency-Graph/index.html': 'graph',
}


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--site', type=Path, default=DOC / '_out/site/pages-public')
    args = parser.parse_args()
    site = args.site.resolve()
    out = DOC / '_out/qa'
    out.mkdir(parents=True, exist_ok=True)
    assert (site / 'index.html').is_file(), f'Build/export the site first: {site}'
    browser_path = os.environ.get('BLUEPRINT_BROWSER')
    if browser_path:
        browser_path = shutil.which(browser_path)
    else:
        browser_path = next((path for name in ('chromium', 'google-chrome',
                             'google-chrome-stable', 'chromium-browser')
                             if (path := shutil.which(name))), None)
    assert browser_path, 'Set BLUEPRINT_BROWSER to an installed Chromium/Chrome executable.'
    pages = [site / 'index.html', *sorted(p for p in site.rglob('*.html')
             if p != site / 'index.html' and 'source' not in p.relative_to(site).parts)]
    missing = [name for name in SCREENSHOTS if not (site / name).is_file()]
    assert not missing, f'Missing expected screenshot pages: {missing}'
    report = {'status': 'running', 'site': str(site), 'prefix': f'/{PREFIX}/',
              'browser': browser_path, 'results': [], 'screenshots': []}
    current_page = None
    current_label = 'startup'
    try:
        from playwright.sync_api import sync_playwright
        # Nothing is served at /. This catches assets that escape the deployment prefix.
        with tempfile.TemporaryDirectory(prefix='blueprint-qa-') as directory:
            (Path(directory) / PREFIX).symlink_to(site, target_is_directory=True)
            server = ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(
                QuietHandler, directory=directory))
            threading.Thread(target=server.serve_forever, daemon=True).start()
            origin = f'http://127.0.0.1:{server.server_port}'
            try:
                with sync_playwright() as playwright:
                    browser = playwright.chromium.launch(executable_path=browser_path, headless=True)
                    try:
                        for label, width, height in [('desktop', 1440, 1000), ('narrow', 390, 844)]:
                            current_label = label
                            page = browser.new_page(viewport={'width': width, 'height': height}, device_scale_factor=1)
                            current_page = page
                            errors = []
                            page.on('pageerror', lambda error: errors.append(str(error)))
                            page.on('requestfailed', lambda request: errors.append(
                                f'{request.url}: {request.failure}'))
                            page.on('response', lambda response: errors.append(
                                f'HTTP {response.status}: {response.url}')
                                if response.status >= 400 and response.url.startswith(origin)
                                and urlsplit(response.url).path != '/favicon.ico' else None)
                            for path in pages:
                                relative = path.relative_to(site).as_posix()
                                response = page.goto(f'{origin}/{PREFIX}/{relative}', wait_until='networkidle')
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
                                    tooltip = page.locator('[data-tippy-root]').first
                                    tooltip.wait_for(state='visible', timeout=10000)
                                    assert tooltip.inner_text().strip(), relative
                                    page.mouse.move(0, 0)
                                    page.wait_for_timeout(300)
                                if relative in SCREENSHOTS:
                                    page.evaluate('window.scrollTo(0, 0)')
                                    filename = f'{label}-{SCREENSHOTS[relative]}.png'
                                    page.screenshot(path=str(out / filename), full_page=True)
                                    report['screenshots'].append(filename)
                                assert not errors, (relative, errors)
                                report['results'].append({'viewport': label, 'page': relative, **metrics})
                            page.close()
                            current_page = None
                    finally:
                        browser.close()
            finally:
                server.shutdown()
                server.server_close()
        report['status'] = 'passed'
    except Exception as error:
        report['status'] = 'failed'
        report['error'] = str(error)
        if current_page is not None and not current_page.is_closed():
            try:
                current_page.screenshot(path=str(out / f'{current_label}-failure.png'), full_page=True)
            except Exception:
                pass
        raise
    finally:
        (out / 'browser-qa.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"Checked {len(report['results'])} page/viewport combinations under /{PREFIX}/; artifacts: {out}")


if __name__ == '__main__':
    main()
