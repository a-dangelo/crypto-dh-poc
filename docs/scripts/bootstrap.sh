#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export LEAN_NUM_THREADS=${LEAN_NUM_THREADS:-2}
export MATHLIB_CACHE_DIR=${MATHLIB_CACHE_DIR:-$PWD/.lake/mathlib-cache}
# The shared book replays committed extraction under the explicit patched runtime.
# Independent extraction toolchains remain available in each Examples package.
bash ../Examples/HashCommitment/scripts/bootstrap.sh --runtime-only
bash DH/scripts/bootstrap-docs.sh
lake exe cache get
