#!/usr/bin/env bash
# Replay extraction, compile proofs, and audit advertised theorem dependencies.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$ROOT/evidence"
"$ROOT/scripts/check-toolchain.sh"
export RUSTUP_TOOLCHAIN=$(python3 -c 'import pathlib,sys,tomllib; print(tomllib.loads(pathlib.Path(sys.argv[1]).read_text())["toolchain"]["channel"])' "$ROOT/vendor/aeneas/charon/rust-toolchain")
(cd "$ROOT/rust"; cargo test --locked) 2>&1 | tee "$ROOT/evidence/rust-tests.log"
"$ROOT/scripts/check-extraction.sh"
(cd "$ROOT/lean"; lake build) 2>&1 | tee "$ROOT/evidence/lean-build.log"
"$ROOT/scripts/audit.sh"
python3 "$ROOT/scripts/record-evidence.py"
