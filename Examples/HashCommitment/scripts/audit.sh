#!/usr/bin/env bash
# Audit the concrete advertised endpoints listed in lean/AxiomAudit.lean.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
LAKE_ROOT=${LAKE_ROOT:-"$ROOT/lean"}
AXIOM_LOG=${AXIOM_LOG:-"$ROOT/evidence/axioms.log"}
mkdir -p "$(dirname "$AXIOM_LOG")"
[[ -f "$ROOT/lean/AxiomAudit.lean" ]] || { echo 'Missing concrete endpoint axiom audit.' >&2; exit 1; }
(cd "$LAKE_ROOT"; lake env lean "$ROOT/lean/AxiomAudit.lean") 2>&1 | tee "$AXIOM_LOG"
python3 - "$AXIOM_LOG" <<'PY_AUDIT'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
allowed = {'propext', 'Classical.choice', 'Quot.sound'}
reports = re.findall(r"depends on axioms: \[([^\]]*)\]", text)
if not reports and 'does not depend on any axioms' not in text:
    raise SystemExit('No theorem dependency reports found.')
for report in reports:
    unexpected = {a.strip() for a in report.split(',') if a.strip()} - allowed
    if unexpected:
        raise SystemExit('Unexpected endpoint axioms: ' + ', '.join(sorted(unexpected)))
print('Endpoint audit: only standard logical axioms occur.')
PY_AUDIT
