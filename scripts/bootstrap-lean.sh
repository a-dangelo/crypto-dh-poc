#!/usr/bin/env bash
# Requires Git, curl, tar, sha256sum, elan, rustup, and official upstream access.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$ROOT/vendor"
clone_pin() {
  local name=$1 url=$2 revision=$3
  if [[ ! -d "$ROOT/vendor/$name" ]]; then
    git clone "$url" "$ROOT/vendor/$name"
    git -C "$ROOT/vendor/$name" checkout --detach "$revision"
  fi
  test "$(git -C "$ROOT/vendor/$name" rev-parse HEAD)" = "$revision"
}
BUNDLE="$ROOT/vendor/aeneas"
TAG=nightly-2026.11.08-c5eb4a2
if [[ ! -d "$BUNDLE" ]]; then
  [[ "$(uname -sm)" == "Linux x86_64" ]] || { echo 'This recipe targets Linux x86_64.' >&2; exit 1; }
  archive=$(mktemp)
  trap 'rm -f "$archive"' EXIT
  curl -fL "https://github.com/AeneasVerif/aeneas/releases/download/$TAG/aeneas-linux-x86_64.tar.gz" -o "$archive"
  echo "2fe983cc442f7943b18afd10eb577c87c15724b9ca542ee037937f2dc5abe97b  $archive" | sha256sum --check
  mkdir -p "$BUNDLE"
  tar -xzf "$archive" -C "$BUNDLE"
fi
if [[ -x "$BUNDLE/aeneas" ]]; then
  [[ "$("$BUNDLE/aeneas" -version)" == "aeneas $TAG" ]]
  (cd "$BUNDLE" && rustup toolchain install --no-self-update)
else
  test "$(git -C "$BUNDLE" rev-parse HEAD)" = c5eb4a28cef65e0aa27743105308243e535a2a2b
fi
clone_pin VCVio https://github.com/Verified-zkEVM/VCVio.git \
  88efe9715a9fa9e7d89635c38cf70259836766c2
cd "$ROOT/lean"
lake update
lake exe cache get
