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
mkdir -p ../Examples/Schnorr/evidence
# Audit Schnorr against the same dependency environment used to render the book.
# The audit imports the aggregate Schnorr module, not only chapter dependencies.
lake build ExamplesBlueprint Schnorr
AXIOM_LOG=../Examples/Schnorr/evidence/blueprint-axioms.log
if ! lake env lean ../Examples/Schnorr/scripts/axioms.lean > "$AXIOM_LOG" 2>&1; then
  cat "$AXIOM_LOG" >&2
  exit 1
fi
python3 ../Examples/Schnorr/scripts/check-axioms.py ../Examples/Schnorr/evidence/blueprint-axioms.log
python3 -c 'import shutil; shutil.rmtree("_out/site", ignore_errors=True)'
lake exe vbp build
python3 DH/scripts/prepare-site.py --replay-directory "$AUDIT_DIR"
python3 Schnorr/scripts/prepare-site.py
lake exe vbp check
python3 scripts/check-site.py
