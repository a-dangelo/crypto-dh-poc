#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
AUDIT_DIR=${DH_REPLAY_DIRECTORY:-$(mktemp -d)}
python3 DH/scripts/test-proof-replay.py
if [[ -n "${DH_REPLAY_DIRECTORY:-}" ]]; then
  python3 -c 'import sys; sys.path.insert(0,"DH/scripts"); from proof_replay import check_replay; from pathlib import Path; check_replay(Path(sys.argv[1]))' "$AUDIT_DIR"
else
  python3 DH/scripts/proof_replay.py --directory "$AUDIT_DIR"
fi
mkdir -p _out/shared-runtime-audit
# Build all proof packages in the dependency environment used to render the book.
# Each audit below checks endpoint dependencies in that same environment.
lake build ExamplesBlueprint Concrete DhPoc Schnorr HashCommitment
AXIOM_LOG=_out/shared-runtime-audit/schnorr-axioms.log
if ! lake env lean ../Examples/Schnorr/scripts/axioms.lean > "$AXIOM_LOG" 2>&1; then
  cat "$AXIOM_LOG" >&2
  exit 1
fi
python3 ../Examples/Schnorr/scripts/check-axioms.py "$AXIOM_LOG"
# Repeat the DH endpoint audit under this book's patched runtime. The historical
# standalone replay above remains separate and retains its original meaning.
SHARED_DH_AUDIT=$(mktemp -d)
for kind in concrete generic parameterized; do
  if ! lake env lean "../Examples/DH/scripts/check-${kind}-axioms.lean" > "$SHARED_DH_AUDIT/${kind}-axioms.log" 2>&1; then
    cat "$SHARED_DH_AUDIT/${kind}-axioms.log" >&2
    exit 1
  fi
done
python3 - "$SHARED_DH_AUDIT" <<'PY_AUDIT'
from pathlib import Path
import sys
sys.path.insert(0, 'DH/scripts')
from proof_replay import check_logs, source_checks
check_logs(Path(sys.argv[1]), source_checks())
PY_AUDIT
LAKE_ROOT="$PWD" AXIOM_LOG="$PWD/../Examples/HashCommitment/evidence/blueprint-axioms.log" \
  bash ../Examples/HashCommitment/scripts/audit.sh
python3 ../Examples/HashCommitment/scripts/record-shared-audit.py --lake-root "$PWD"

mkdir -p _out/shared-runtime-audit
cp "$SHARED_DH_AUDIT/"*-axioms.log _out/shared-runtime-audit/
python3 -c 'import shutil; shutil.rmtree("_out/site", ignore_errors=True)'
lake exe vbp build
python3 DH/scripts/prepare-site.py --replay-directory "$AUDIT_DIR"
python3 Schnorr/scripts/prepare-site.py
python3 HashCommitment/scripts/prepare-site.py
lake exe vbp check
python3 scripts/check-site.py
