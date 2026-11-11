#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export PATH="$ROOT/vendor/aeneas:$PATH"
export RUSTUP_TOOLCHAIN=nightly-2026-09-17
[[ "$(aeneas -version)" == 'aeneas nightly-2026.11.08-c5eb4a2' ]]
OUT=${1:-"$ROOT/lean/Schnorr/Generated"}
mkdir -p "$OUT" "$ROOT/evidence"
cd "$ROOT/rust"
export CARGO_TARGET_DIR="${AENEAS_TARGET_DIR:-$ROOT/rust/target/aeneas}"
charon cargo --preset=aeneas --sysroot "${MIRI_SYSROOT:-default}" \
  --dest-file "$ROOT/evidence/schnorr_core.llbc" -- -p schnorr-core
aeneas -backend lean -namespace schnorr_core -dest "$OUT" "$ROOT/evidence/schnorr_core.llbc"
