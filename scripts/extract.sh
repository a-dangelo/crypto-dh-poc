#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-"$ROOT/lean/DhPoc/Generated"}
mkdir -p "$OUT" "$ROOT/evidence"
cd "$ROOT/rust"
export CARGO_TARGET_DIR="${AENEAS_TARGET_DIR:-$ROOT/rust/target/aeneas-core}"
charon cargo --preset=aeneas --sysroot "${MIRI_SYSROOT:-default}" \
  --dest-file "$ROOT/evidence/dh_core.llbc" -- -p dh-core
# Generated source is never patched by hand.
aeneas -backend lean -namespace dh_core -dest "$OUT" "$ROOT/evidence/dh_core.llbc"
