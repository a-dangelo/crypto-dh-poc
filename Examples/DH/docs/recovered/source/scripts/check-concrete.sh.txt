#!/usr/bin/env bash
# Default: regenerate the concrete Rust extraction. --proof-only skips regeneration.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export POC_CHECK_MODE="${1:-full}"
export PATH="$ROOT/vendor/aeneas-dalek:$PATH"
[[ "$(aeneas -version)" == 'aeneas nightly-2026.10.30-de16f3c' ]]
mkdir -p "$ROOT/concrete/evidence"
if [[ "${1:-}" != '--proof-only' ]]; then
  "$ROOT/scripts/extract-concrete.sh" > "$ROOT/concrete/evidence/extract.log" 2>&1
  echo exit_code=0 >> "$ROOT/concrete/evidence/extract.log"
  python3 "$ROOT/scripts/slice-concrete.py" --check
fi
(cd "$ROOT/concrete" && lake build) 2>&1 | tee "$ROOT/concrete/evidence/final-build.log"
(cd "$ROOT/concrete" && lake env lean Concrete/Audit.lean) > "$ROOT/concrete/evidence/axioms.log" 2>&1
if [[ -d "$ROOT/vendor/dalek-extraction" ]]; then
  (cd "$ROOT/concrete/rust/smoke" && \
    RUSTFLAGS='--cfg curve25519_dalek_backend="serial"' cargo run --locked) \
    > "$ROOT/concrete/evidence/smoke.log" 2>&1
fi
python3 "$ROOT/scripts/check-concrete-evidence.py"
