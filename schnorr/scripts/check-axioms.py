#!/usr/bin/env python3
"""Check the complete dependency closures of all advertised Schnorr endpoints."""
import re
import sys
from pathlib import Path
expected = {'SchnorrProof.honest_complete', 'SchnorrProof.messages_eq', 'SchnorrProof.special_soundness', 'SchnorrProof.rustTranscript_eq_batch', 'SchnorrProof.perfect_hvzk', 'SchnorrProof.encodedSimulator_eq', 'SchnorrProof.rustTranscript_eq_encodedReal', 'SchnorrProof.observeMessages_fail', 'SchnorrProof.commit_eq', 'SchnorrProof.verify_accepts_iff', 'SchnorrProof.observeMessages_div', 'SchnorrProof.public_eq', 'SchnorrProof.respond_eq', 'SchnorrProof.verify_eq'}
expected |= {'SchnorrProof.batchTranscript_eq_encodedReal', 'SchnorrProof.Randomness.runtime_commitment_eq', 'SchnorrProof.Randomness.ideal_commitment_eq', 'SchnorrProof.Randomness.ideal_commitment_refines'}
text = Path(sys.argv[1]).read_text()
assert not re.search(r"\b(?:error|sorryAx)\b", text), text
found = {}
for name, body in re.findall(r"'([^']+)' depends on axioms:\s*\[([^\]]*)\]", text):
    assert name not in found, f"Duplicate endpoint: {name}"
    found[name] = {x.strip() for x in body.split(',') if x.strip()}
for name in re.findall(r"'([^']+)' does not depend on any axioms", text):
    assert name not in found, f"Duplicate endpoint: {name}"
    found[name] = set()
assert set(found) == expected, ("Endpoint mismatch", expected - set(found), set(found) - expected)
allowed = {"propext", "Classical.choice", "Quot.sound"}
for name, axioms in found.items():
    assert axioms <= allowed, (name, axioms - allowed)
print(f"Audited {len(found)} Schnorr endpoints; only standard Lean axioms occur.")
