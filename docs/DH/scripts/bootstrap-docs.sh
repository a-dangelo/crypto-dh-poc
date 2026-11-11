#!/usr/bin/env bash
# Prepare the pinned Linux proof/docs stack. No Rust extraction is performed.
# Requires Git, Python 3, and official elan with Lean 4.35.0 already installed.
set -euo pipefail

DOC=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ROOT=$(cd -- "$DOC/../../Examples/DH" && pwd)
TOOLCHAIN=leanprover/lean4:v4.35.0
export LEAN_NUM_THREADS=${LEAN_NUM_THREADS:-2}

fail() { printf 'bootstrap-docs: %s\n' "$*" >&2; exit 1; }
[[ "$(uname -sm)" == 'Linux x86_64' ]] || fail 'Linux x86_64 is required.'
for command in git python3 elan; do
  command -v "$command" >/dev/null || fail "Missing required command: $command"
done
[[ "$(cat "$ROOT/concrete/lean-toolchain")" == "$TOOLCHAIN" ]] || fail 'Unexpected concrete toolchain.'
[[ "$(cat "$DOC/lean-toolchain")" == "$TOOLCHAIN" ]] || fail 'Unexpected Blueprint toolchain.'
[[ -f "$DOC/lake-manifest.json" ]] || fail 'The committed Blueprint manifest is required.'
elan run "$TOOLCHAIN" lean --version

check_snapshot() {
  python3 "$DOC/scripts/check-sources.py"
  python3 - "$DOC/lake-manifest.json" <<'PY_PIN'
import json
import sys
manifest = json.load(open(sys.argv[1]))
verso = next(p for p in manifest['packages'] if p['name'] == 'VersoBlueprint')
assert verso['rev'] == '4943d3335ffa9221a39949e60836a8ad5dc2a456'
print('Verified the Blueprint dependency pin.')
PY_PIN
}

clone_pin() {
  local destination=$1 url=$2 revision=$3 head
  if [[ ! -e "$destination/.git" ]]; then
    [[ ! -e "$destination" || -d "$destination" ]] || fail "Not a directory: $destination"
    [[ ! -d "$destination" || -z "$(ls -A "$destination")" ]] || fail "Refusing to replace non-repository directory: $destination"
    mkdir -p "$destination"
    git -C "$destination" init -q
    git -C "$destination" remote add origin "$url"
  fi
  [[ "$(git -C "$destination" remote get-url origin)" == "$url" ]] || fail "Unexpected origin: $destination"
  [[ -z "$(git -C "$destination" status --porcelain --untracked-files=normal)" ]] || fail "Dependency has local changes: $destination"
  head=$(git -C "$destination" rev-parse --verify HEAD 2>/dev/null || true)
  if [[ -z "$head" ]]; then
    git -C "$destination" fetch --depth 1 --no-tags origin "$revision"
    git -C "$destination" checkout --detach "$revision"
  else
    [[ "$head" == "$revision" ]] || fail "Wrong cached revision in $destination: $head (expected $revision)"
  fi
  [[ "$(git -C "$destination" rev-parse HEAD)" == "$revision" ]] || fail "Revision verification failed: $destination"
}

check_snapshot
clone_pin "$ROOT/vendor/VCVio" \
  https://github.com/Verified-zkEVM/VCVio.git \
  88efe9715a9fa9e7d89635c38cf70259836766c2
clone_pin "$ROOT/vendor/dalek-proof" \
  https://github.com/Beneficial-AI-Foundation/curve25519-dalek-fork.git \
  95b5831c63ff1c5f6287bd3a77569412a9afdbfb
clone_pin "$ROOT/concrete/vendor/EllipticCurve" \
  https://github.com/Beneficial-AI-Foundation/elliptic-curve.git \
  4015c7cfab714640e77500bdbde6e64face3fbaa
clone_pin "$ROOT/vendor/aeneas-dalek" \
  https://github.com/AeneasVerif/aeneas.git \
  de16f3cf877976e966906dc890f63dcb418884fa
clone_pin "$ROOT/lean/.lake/packages/mathlib" \
  https://github.com/leanprover-community/mathlib4.git \
  56a005855ea17e0b0958f73ec801ae140b0a1679

# Lake uses this exact upstream tag to locate Aeneas's Lean build cache.
# This downloads no Charon/Aeneas extraction binaries or Rust toolchains.
AENEAS_TAG=nightly-2026.10.30-de16f3c
if ! git -C "$ROOT/vendor/aeneas-dalek" show-ref --verify --quiet "refs/tags/$AENEAS_TAG"; then
  git -C "$ROOT/vendor/aeneas-dalek" fetch --depth 1 --no-tags origin \
    "refs/tags/$AENEAS_TAG:refs/tags/$AENEAS_TAG"
fi
[[ "$(git -C "$ROOT/vendor/aeneas-dalek" rev-parse "$AENEAS_TAG^{commit}")" == \
  de16f3cf877976e966906dc890f63dcb418884fa ]] || fail 'Unexpected Aeneas release tag.'

# Use committed manifests. Do not run lake update: the core manifests are audited.
# Each root has its own transitive-package directory, so prepare both caches.
(cd "$ROOT/concrete" && elan run "$TOOLCHAIN" lake exe cache get)
(cd "$DOC/.." && elan run "$TOOLCHAIN" lake exe cache get)
check_snapshot
printf 'Pinned proof/docs dependencies are ready. No Rust extraction was run.\n'
