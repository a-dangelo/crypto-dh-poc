#!/usr/bin/env bash
# Linux x86_64. Requires Git, curl, tar, sha256sum, elan and rustup.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
[[ "$(uname -sm)" == "Linux x86_64" ]] || { echo 'This recipe targets Linux x86_64.' >&2; exit 1; }
[[ -d "$ROOT/lean/.lake/packages/mathlib" ]] || "$ROOT/scripts/bootstrap-lean.sh"
clone_pin() {
  local dest=$1 url=$2 rev=$3
  if [[ ! -d "$dest" ]]; then
    git clone "$url" "$dest"
    git -C "$dest" checkout --detach "$rev"
  fi
  test "$(git -C "$dest" rev-parse HEAD)" = "$rev"
}
clone_pin "$ROOT/vendor/dalek-proof" https://github.com/Beneficial-AI-Foundation/curve25519-dalek-fork.git 95b5831c63ff1c5f6287bd3a77569412a9afdbfb
mkdir -p "$ROOT/concrete/vendor"
clone_pin "$ROOT/concrete/vendor/EllipticCurve" https://github.com/Beneficial-AI-Foundation/elliptic-curve.git 4015c7cfab714640e77500bdbde6e64face3fbaa
TAG=nightly-2026.10.30-de16f3c
BUNDLE="$ROOT/vendor/aeneas-dalek"
if [[ ! -x "$BUNDLE/aeneas" ]]; then
  archive=$(mktemp)
  trap 'rm -f "$archive"' EXIT
  curl -fL "https://github.com/AeneasVerif/aeneas/releases/download/$TAG/aeneas-linux-x86_64.tar.gz" -o "$archive"
  echo "0963dc77cab890de16b213b903091721961afca6303b9b0ea05ff8d76013f624  $archive" | sha256sum --check
  mkdir -p "$BUNDLE"
  tar -xzf "$archive" -C "$BUNDLE"
fi
[[ "$("$BUNDLE/aeneas" -version)" == "aeneas $TAG" ]]
(cd "$BUNDLE" && rustup toolchain install --no-self-update)
(cd "$ROOT/concrete" && lake update && lake exe cache get)
