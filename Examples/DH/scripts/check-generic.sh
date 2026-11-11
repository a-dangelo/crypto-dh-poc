#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ -x "$ROOT/vendor/aeneas/aeneas" ]]; then
  export PATH="$ROOT/vendor/aeneas:$PATH"
fi
[[ "$(aeneas -version)" == "aeneas nightly-2026.11.08-c5eb4a2" ]]
mkdir -p "$ROOT/evidence"
cd "$ROOT/rust"
cargo test --workspace --locked 2>&1 | tee "$ROOT/evidence/rust-tests.log"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
"$ROOT/scripts/extract.sh" "$TMP" 2>&1 | tee "$ROOT/evidence/extraction-check.log"
diff -u "$ROOT/lean/DhPoc/Generated/DhCore.lean" "$TMP/DhCore.lean"
cd "$ROOT/lean"
lake build 2>&1 | tee "$ROOT/evidence/lean-build.log"
lake env lean ../scripts/check-generic-axioms.lean | tee "$ROOT/evidence/axioms.log"
python3 "$ROOT/scripts/check-evidence.py"
