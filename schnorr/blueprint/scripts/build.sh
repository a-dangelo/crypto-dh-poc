#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Build the proof before requesting source-aware declaration panels.
mkdir -p ../evidence
(cd ../lean && lake build && lake env lean ../scripts/axioms.lean > ../evidence/blueprint-axioms.log 2>&1)
python3 ../scripts/check-axioms.py ../evidence/blueprint-axioms.log
lake build
lake exe vbp build
python3 scripts/prepare-site.py
lake exe vbp check
python3 scripts/check-site.py
