#!/usr/bin/env bash
# Regenerate Lean from Rust. The generated output is never edited semantically.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
"$ROOT/scripts/check-toolchain.sh"
OUT=${1:-"$ROOT/lean/HashCommitment/Generated"}
EVIDENCE=${HASH_COMMITMENT_EVIDENCE:-"$ROOT/evidence"}
mkdir -p "$OUT" "$EVIDENCE"
export PATH="$ROOT/vendor/aeneas/charon/bin:${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"
export RUSTUP_TOOLCHAIN=$(python3 -c 'import pathlib,sys,tomllib; print(tomllib.loads(pathlib.Path(sys.argv[1]).read_text())["toolchain"]["channel"])' "$ROOT/vendor/aeneas/charon/rust-toolchain")
export CARGO_TARGET_DIR="${AENEAS_TARGET_DIR:-$ROOT/rust/target/aeneas}"
cd "$ROOT/rust"
charon cargo --preset=aeneas --sysroot "${MIRI_SYSROOT:-default}" \
  --dest-file "$EVIDENCE/hash_commitment.llbc" -- -p hash_commitment
"$ROOT/vendor/aeneas/bin/aeneas" -backend lean -probabilistic \
  -namespace HashCommitment.Extracted -dest "$OUT" "$EVIDENCE/hash_commitment.llbc"
python3 "$ROOT/scripts/normalize-generated-paths.py" "$OUT"
