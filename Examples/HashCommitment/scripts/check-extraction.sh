#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT
mkdir -p "$ROOT/evidence"
"$ROOT/scripts/extract.sh" "$OUT/probabilistic" 2>&1 | tee "$ROOT/evidence/extraction.log"
diff -ru "$ROOT/lean/HashCommitment/Generated" "$OUT/probabilistic"
# The same LLBC is also extracted in ordinary mode to demonstrate the optimization.
mkdir -p "$OUT/ordinary"
"$ROOT/vendor/aeneas/bin/aeneas" -backend lean \
  -namespace HashCommitment.Extracted -dest "$OUT/ordinary" "$ROOT/evidence/hash_commitment.llbc"
python3 "$ROOT/scripts/check-extraction-regression.py" \
  "$OUT/probabilistic/HashCommitment.lean" "$OUT/ordinary/HashCommitment.lean" \
  | tee "$ROOT/evidence/extraction-regression.log"
