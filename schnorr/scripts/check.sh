#!/usr/bin/env bash
# Full replay by default. --proof-only skips Rust compilation and extraction.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export LEAN_NUM_THREADS=${LEAN_NUM_THREADS:-2}
export PATH="$ROOT/vendor/aeneas:$PATH"
export RUSTUP_TOOLCHAIN=nightly-2026-09-17
MODE=${1:-full}
[[ "$MODE" == full || "$MODE" == --proof-only ]] || { echo 'Use no arguments or --proof-only.' >&2; exit 1; }
mkdir -p "$ROOT/evidence"
if [[ "$MODE" == full ]]; then
  (cd "$ROOT/rust" && cargo fmt --check && cargo test --locked) 2>&1 | tee "$ROOT/evidence/rust-tests.log"
  (cd "$ROOT/rust/native" && cargo fmt --check && cargo test --locked) 2>&1 | tee "$ROOT/evidence/ristretto-tests.log"
  out=$(mktemp -d)
  trap 'rm -rf "$out"' EXIT
  "$ROOT/scripts/extract.sh" "$out" 2>&1 | tee "$ROOT/evidence/extraction.log"
  diff -u "$ROOT/lean/Schnorr/Generated/SchnorrCore.lean" "$out/SchnorrCore.lean"
fi
(cd "$ROOT/lean" && lake build Schnorr) 2>&1 | tee "$ROOT/evidence/lean-build.log"
(cd "$ROOT/lean" && lake env lean ../scripts/axioms.lean) > "$ROOT/evidence/axioms.log" 2>&1
python3 "$ROOT/scripts/check-axioms.py" "$ROOT/evidence/axioms.log"
python3 "$ROOT/scripts/check-isolation.py"
python3 "$ROOT/scripts/record-evidence.py" --mode="$MODE"
printf 'Schnorr checks passed (%s).\n' "$MODE"
