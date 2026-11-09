#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
AUDIT_DIR=$(mktemp -d)
trap 'rm -rf "$AUDIT_DIR"' EXIT
python3 scripts/test-proof-replay.py
python3 scripts/proof_replay.py --directory "$AUDIT_DIR"
python3 -c 'import shutil; shutil.rmtree("_out/site", ignore_errors=True)'
lake exe vbp build
python3 scripts/prepare-site.py --replay-directory "$AUDIT_DIR"
python3 scripts/check-site.py
