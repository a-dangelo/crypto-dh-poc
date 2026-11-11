#!/usr/bin/env bash
# Independent Linux x86_64 dependencies; no DH source or package is required.
# Prerequisites: git, curl, tar, sha256sum, elan, rustup, Python 3.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[[ "$(uname -sm)" == "Linux x86_64" ]] || { echo 'Linux x86_64 is required.' >&2; exit 1; }
export LEAN_NUM_THREADS=${LEAN_NUM_THREADS:-2}
export MATHLIB_CACHE_DIR=${MATHLIB_CACHE_DIR:-$ROOT/vendor/mathlib-cache}
mkdir -p "$ROOT/vendor"
clone_pin() {
  local dest=$1 url=$2 rev=$3
  if [[ ! -e "$dest" ]]; then
    mkdir -p "$dest"
    git -C "$dest" init -q
    git -C "$dest" remote add origin "$url"
    git -C "$dest" fetch --depth 1 --no-tags origin "$rev"
    git -C "$dest" checkout --detach "$rev"
  fi
  [[ "$(git -C "$dest" rev-parse HEAD)" == "$rev" ]]
  [[ -z "$(git -C "$dest" status --porcelain --untracked-files=no)" ]]
}
clone_pin "$ROOT/vendor/VCVio" https://github.com/Verified-zkEVM/VCVio.git \
  88efe9715a9fa9e7d89635c38cf70259836766c2
TAG=nightly-2026.11.08-c5eb4a2
BUNDLE="$ROOT/vendor/aeneas"
if [[ ! -x "$BUNDLE/aeneas" ]]; then
  archive=$(mktemp)
  trap 'rm -f "$archive"' EXIT
  curl --fail --location --retry 3 \
    "https://github.com/AeneasVerif/aeneas/releases/download/$TAG/aeneas-linux-x86_64.tar.gz" \
    --output "$archive"
  echo "2fe983cc442f7943b18afd10eb577c87c15724b9ca542ee037937f2dc5abe97b  $archive" | sha256sum --check
  mkdir -p "$BUNDLE"
  tar -xzf "$archive" -C "$BUNDLE"
fi
[[ "$("$BUNDLE/aeneas" -version)" == "aeneas $TAG" ]]
[[ "$(cat "$BUNDLE/backends/lean/lean-toolchain")" == 'leanprover/lean4:v4.35.0' ]]
elan toolchain install leanprover/lean4:v4.35.0
# The official cache is an optimization for the same pinned source release.
if [[ ! -f "$BUNDLE/backends/lean/.lake/build/lib/lean/Aeneas.olean" ]]; then
  cache=$(mktemp)
  trap 'rm -f "${archive:-}" "${cache:-}"' EXIT
  curl --fail --location --retry 3 \
    "https://github.com/AeneasVerif/aeneas/releases/download/$TAG/lean-build-aeneas-x86_64-unknown-linux-gnu.tar.gz" \
    --output "$cache"
  echo "fb7281038f536cd29ae4f3f213f87451cd7380c0cef6e15b5bb2f65885afb74d  $cache" | sha256sum --check
  mkdir -p "$BUNDLE/backends/lean/.lake/build"
  tar -xzf "$cache" -C "$BUNDLE/backends/lean/.lake/build"
fi
rustup toolchain install nightly-2026-09-17 --profile minimal \
  --component rustc-dev,llvm-tools,rust-src,miri,rustfmt --no-self-update
# The lockfile is part of the artifact; routine replay must not re-resolve pins.
[[ -f "$ROOT/lean/lake-manifest.json" ]]
(cd "$ROOT/lean" && lake exe cache get)
printf 'Schnorr dependencies are ready. Add %s to PATH for extraction.\n' "$BUNDLE"
