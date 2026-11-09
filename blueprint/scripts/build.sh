#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/.."
python3 scripts/check-sources.py
AUDIT_DIR=$(mktemp -d)
trap 'rm -rf "$AUDIT_DIR"' EXIT
(cd ../concrete && lake build Concrete DhPoc)
(cd ../concrete && lake env lean ../scripts/check-concrete-axioms.lean) > "$AUDIT_DIR/concrete.log"
(cd ../concrete && lake env lean ../scripts/check-generic-axioms.lean) > "$AUDIT_DIR/generic.log"
python3 scripts/check-sources.py --concrete-axioms "$AUDIT_DIR/concrete.log" --generic-axioms "$AUDIT_DIR/generic.log"
python3 -c 'import shutil; shutil.rmtree("_out/site", ignore_errors=True)'
lake exe vbp build
python3 scripts/prepare-site.py
python3 scripts/check-site.py
