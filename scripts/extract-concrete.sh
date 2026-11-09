#!/usr/bin/env bash
# Extract the patched concrete backend and retain its evidence separately from the generic proof.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SRC="$ROOT/vendor/dalek-proof"
WORK="$ROOT/vendor/dalek-extraction"
test "$(git -C "$SRC" rev-parse HEAD)" = 95b5831c63ff1c5f6287bd3a77569412a9afdbfb
git -C "$SRC" diff --quiet HEAD -- curve25519-dalek Cargo.toml Cargo.lock
mkdir -p "$ROOT/concrete/evidence" "$WORK"
python3 - "$ROOT" <<'PY'
import pathlib, shutil, sys
root=pathlib.Path(sys.argv[1]); src=root/'vendor/dalek-proof'; work=root/'vendor/dalek-extraction'
for name in ['Cargo.toml','Cargo.lock']:
    shutil.copy2(src/name, work/name)
for name in ['curve25519-dalek','curve25519-dalek-derive','ed25519-dalek','x25519-dalek']:
    shutil.copytree(src/name, work/name, dirs_exist_ok=True,
        ignore=shutil.ignore_patterns('target','lean'))
shutil.copy2(root/'concrete/rust/poc_dh.rs', work/'curve25519-dalek/src/poc_dh.rs')
p=work/'curve25519-dalek/src/lib.rs'
p.write_text(p.read_text()+'\n/// Proof-of-concept protocol wrapper.\npub mod poc_dh;\n')
PY
for patch in "$SRC"/curve25519-dalek/translation-patches/*.patch; do
  (cd "$WORK" && GIT_CEILING_DIRECTORIES="$ROOT/vendor" git apply "$patch")
done
# Fail if Git silently skipped patches because an outer repository was discovered.
grep -q 'for i in 0..dst.len()' "$WORK/curve25519-dalek/src/scalar.rs"
grep -q 'pub(crate) fn mul(point: &EdwardsPoint, s: &Scalar)' "$WORK/curve25519-dalek/src/backend/serial/scalar_mul/variable_base.rs"
mkdir -p "$WORK/targets"
export CARGO_TARGET_DIR="$WORK/target"
unset RUSTFLAGS CARGO_ENCODED_RUSTFLAGS
rustc="$(charon toolchain-path)/bin/rustc"
serial='--cfg curve25519_dalek_backend="serial"'
targets=()
for arch in x86_64 i686; do
  for spec in "$arch-tables" "$arch-no-tables"; do
    "$rustc" -Z unstable-options --print target-spec-json --target "$arch-unknown-linux-gnu" > "$WORK/targets/$spec.json"
    targets+=(--targets "$WORK/targets/$spec.json")
  done
  export "CARGO_TARGET_$(tr 'a-z-' 'A-Z_' <<< "$arch-tables")_RUSTFLAGS=$serial --cfg feature=\"precomputed-tables\""
  export "CARGO_TARGET_$(tr 'a-z-' 'A-Z_' <<< "$arch-no-tables")_RUSTFLAGS=$serial"
done
(cd "$WORK/curve25519-dalek" && charon cargo --preset=aeneas "${targets[@]}" \
  --dest-file "$ROOT/concrete/evidence/curve25519_dalek.llbc" \
  -- --locked --no-default-features --features alloc,zeroize \
  -Zjson-target-spec -Zbuild-std=core,alloc)
aeneas -backend lean -split-files -emit-json -namespace Curve25519Dalek \
  -dest "$ROOT/concrete/evidence/generated" -subdir Curve25519Dalek \
  "$ROOT/concrete/evidence/curve25519_dalek.llbc"

python3 "$ROOT/scripts/record-extraction.py"
