#!/usr/bin/env python3
"""Require all parameterized endpoint audits and only Lean's standard axioms."""
from pathlib import Path
import json
import re
import sys

text = Path(sys.argv[1]).read_text()
assert 'sorryAx' not in text, 'Admitted proof in parameterized audit'
expected = {
    'DhPoc.uniform_modulo_measureETVDist_le',
    'DhPoc.pair_bind_distance',
    'DhPoc.sampledDDHAdvantage_le_standard',
    'DhPoc.four_samplingError_le_exp',
    'DhPoc.four_samplingError_negligible',
    'DhPoc.moduloSessionAdvantage_le_standard',
    'DhPoc.parameterizedSessionAdvantage_negligible',
    'DhPoc.parameterizedSession_secure',
    'DhPoc.ParameterizedTests.arithmeticFamily',
    'DhPoc.PPT.precompWitness',
    'DhPoc.PPT.isPPTBy_precomp',
    'DhPoc.PPT.interpretCoins_evalDistEq',
    'DhPoc.PPT.ddhFamily_reduce',
    'DhPoc.PPT.session_secure_isPPTBy',
}
standard = {'propext', 'Classical.choice', 'Quot.sound'}
entries = re.findall(r"'([^']+)' depends on axioms: \[([^]]*)\]", text, re.S)
assert len({name for name, _ in entries}) == len(entries), 'Duplicate audit declarations'
closures = {name: {x.strip() for x in axioms.split(',') if x.strip()}
            for name, axioms in entries}
for name in re.findall(r"'([^']+)' does not depend on any axioms", text):
    assert name not in closures, f'Duplicate audit declaration: {name}'
    closures[name] = set()
assert set(closures) == expected, f'Unexpected audit declarations: {set(closures) ^ expected}'
for name, axioms in closures.items():
    assert axioms <= standard, f'Nonstandard axiom dependency in {name}: {axioms - standard}'
print(json.dumps({'checked_endpoints': len(closures),
                  'axioms': sorted(set().union(*closures.values()))}))
