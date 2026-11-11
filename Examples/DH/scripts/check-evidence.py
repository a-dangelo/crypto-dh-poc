#!/usr/bin/env python3
"""Reject unexpected theorem axioms and record source hashes and line counts."""
import hashlib
import json
import pathlib
import re

root = pathlib.Path(__file__).resolve().parents[1]
lean = sorted((root / "lean" / "DhPoc").rglob("*.lean"))
allowed = {"propext", "Classical.choice", "Quot.sound"}
audit = (root / "evidence" / "axioms.log").read_text()
entries = re.findall(r"'([^']+)' depends on axioms: \[([^]]*)\]", audit)
if len(entries) < 16:
    raise SystemExit(f"Expected at least 16 audited declarations; found {len(entries)}")
for theorem, axioms in entries:
    unexpected = {a.strip() for a in axioms.split(",") if a.strip()} - allowed
    if unexpected:
        raise SystemExit(f"Unexpected axioms in {theorem}: {unexpected}")
for path in lean:
    # The dependency-closure audit is authoritative. This is a second source check.
    code = re.sub(r"/-.*?-/|--[^\n]*", "", path.read_text(), flags=re.S)
    if re.search(r"\b(sorry|admit|axiom)\b", code):
        raise SystemExit(f"Admission or custom axiom declaration in {path}")
files = {}
for path in lean:
    data = path.read_bytes()
    files[str(path.relative_to(root))] = {
        "lines": len(data.splitlines()), "sha256": hashlib.sha256(data).hexdigest()
    }
report = {
    "status": "checked_conditional_vertical_slice",
    "scope": "earlier_generic_prototype_only",
    "authoritative_concrete_report": "concrete/evidence/concrete-proof-report.json",
    "concrete_end_to_end_security_proved": False,
    "checks": ["native Rust tests", "regeneration matches", "Lean build", "axiom closure"],
    "audited_declarations": [name for name, _ in entries],
    "allowed_axioms": sorted(allowed),
    "lean_lines_including_generated_and_audit": sum(f["lines"] for f in files.values()),
    "largest_lean_file_lines": max(f["lines"] for f in files.values()),
    "files": files,
    "open_obligations": [
        "Concrete Ristretto primitive and representation refinement",
        "Runtime randomness and exact raw-secret sampling law",
        "Optional relation to standard DDH: wide reduction bias and game transfer",
        "DDH hypothesis for the chosen group and efficient reduction"
    ]
}
(root / "evidence" / "status.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({k: report[k] for k in ["status", "lean_lines_including_generated_and_audit", "largest_lean_file_lines"]}, indent=2))
