#!/usr/bin/env bash
# Install the pinned source patch; optionally build its extractor.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MODE=${1:---full}
[[ "$MODE" == --full || "$MODE" == --runtime-only ]] || { echo "usage: $0 [--full|--runtime-only]" >&2; exit 2; }
REV=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["aeneas_revision"])' "$ROOT/patches/toolchain.json")
SRC="$ROOT/vendor/aeneas"
python3 - "$ROOT" <<'VERIFY_PATCH'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1]); j=json.loads((r/"patches/toolchain.json").read_text())
assert hashlib.sha256((r/"patches/aeneas-probabilistic.patch").read_bytes()).hexdigest() == j["patch_sha256"], "patch digest mismatch"
VERIFY_PATCH
if [[ ! -d "$SRC/.git" ]]; then
  mkdir -p "$ROOT/vendor"
  git clone https://github.com/AeneasVerif/aeneas.git "$SRC"
  git -C "$SRC" checkout --detach "$REV"
fi
if git -C "$SRC" diff --quiet HEAD; then
  git -C "$SRC" apply "$ROOT/patches/aeneas-probabilistic.patch"
fi
# Materialise the second path dependency for clean Lean checkouts too.
VCVIO_REV=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["vcvio_revision"])' "$ROOT/patches/toolchain.json")
VCVIO="$ROOT/vendor/VCVio"
if [[ ! -d "$VCVIO/.git" ]]; then
  mkdir -p "$ROOT/vendor"
  git clone https://github.com/Verified-zkEVM/VCVio.git "$VCVIO"
  git -C "$VCVIO" checkout --detach "$VCVIO_REV"
fi
# Existing checkouts are verified, never silently reset or cleaned.
"$ROOT/scripts/check-toolchain.sh" runtime
[[ "$MODE" == --runtime-only ]] && exit 0
command -v opam >/dev/null || { echo 'Install OCaml/opam (OCaml 5.3.0) before full bootstrap.' >&2; exit 1; }
# Activate the selected switch in this process; workflow-step environments do
# not persist CAML_LD_LIBRARY_PATH. Assignment separately preserves opam errors.
OPAM_ENV=$(opam env --shell=bash --set-switch)
eval "$OPAM_ENV"
# Only the pinned Charon OCaml sources are needed for the Aeneas source build.
# Upstream setup-charon also runs Rust tests and can mask their failures; the
# matching Charon executables below instead come from a verified release.
CHARON_REV=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["charon_revision"])' "$ROOT/patches/toolchain.json")
if [[ ! -d "$SRC/charon/.git" ]]; then
  git clone https://github.com/AeneasVerif/charon.git "$SRC/charon"
  git -C "$SRC/charon" checkout --detach "$CHARON_REV"
fi
[[ "$(git -C "$SRC/charon" rev-parse HEAD)" == "$CHARON_REV" ]] || {
  echo 'Existing Charon checkout does not match the pinned revision.' >&2
  exit 1
}
(cd "$SRC/charon" && opam exec -- make charon-ml/src/CharonVersion.ml)
opam install dune.3.17.2 -y --jobs="${BUILD_JOBS:-4}"
opam pin add dune 3.17.2 -y --no-action
opam install "$SRC/src" --deps-only -y --jobs="${BUILD_JOBS:-4}"
(cd "$SRC/src" && opam exec -- dune build -j "${BUILD_JOBS:-4}" main.exe)
mkdir -p "$SRC/bin"
# Dune installs executables as mode 555. Replace the directory entry atomically
# instead of opening an existing cached executable for writing.
BINARY_TMP=$(mktemp "$SRC/bin/.aeneas-install.XXXXXX")
trap 'rm -f "$BINARY_TMP"' EXIT
install -m 755 "$SRC/src/_build/default/main.exe" "$BINARY_TMP"
mv -f "$BINARY_TMP" "$SRC/bin/aeneas"
trap - EXIT
python3 - "$ROOT" <<'RECORD'
import hashlib,json,pathlib,sys
r=pathlib.Path(sys.argv[1]); lock=json.loads((r/'patches/toolchain.json').read_text())
s=r/'vendor/aeneas'; lock['binary_sha256']=hashlib.sha256((s/'bin/aeneas').read_bytes()).hexdigest()
(s/'.hash-commitment-build.json').write_text(json.dumps(lock,indent=2)+'\n')
RECORD
# The official binary bundle below targets Linux x86_64. Other platforms must
# build Charon at charon-pin and explicitly update the recorded binary digests.
[[ "$(uname -sm)" == "Linux x86_64" ]] || { echo "Pinned Charon artifact requires Linux x86_64" >&2; exit 1; }
# Charon is the matching upstream artifact, not the unpatched Aeneas binary.
ARCHIVE=$(mktemp)
trap 'rm -f "$ARCHIVE"' EXIT
curl -fL https://github.com/AeneasVerif/aeneas/releases/download/nightly-2026.10.30-de16f3c/aeneas-linux-x86_64.tar.gz -o "$ARCHIVE"
python3 - "$ARCHIVE" <<'CHECK'
import hashlib,pathlib,sys
assert hashlib.sha256(pathlib.Path(sys.argv[1]).read_bytes()).hexdigest() == '0963dc77cab890de16b213b903091721961afca6303b9b0ea05ff8d76013f624'
CHECK
mkdir -p "$SRC/charon/bin"
tar -xzf "$ARCHIVE" -C "$SRC/charon/bin" charon charon-driver
"$ROOT/scripts/check-toolchain.sh"

