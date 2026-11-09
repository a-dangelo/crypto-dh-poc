#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
python3 -c 'import shutil; shutil.rmtree("_out/site", ignore_errors=True)'
lake exe vbp build
python3 scripts/prepare-site.py
python3 scripts/check-site.py
