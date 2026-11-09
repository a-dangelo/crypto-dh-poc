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
    'DhPoc.CoinSampling.sample_rollBound',
    'DhPoc.CoinSampling.sample_evalDist',
    'DhPoc.CoinSampling.sample_evalDistEq',
    'DhPoc.CoinSampling.interpret_sample_evalDistEq',
    'DhPoc.CoinSampling.sample_polynomial_rollBound',
    'DhPoc.CoinSecurity.real_evalDistEq',
    'DhPoc.CoinSecurity.ideal_evalDistEq',
    'DhPoc.CoinSecurity.bind_distance_le',
    'DhPoc.CoinSecurity.ideal_distance_le',
    'DhPoc.CoinSecurity.advantage_le_standard',
    'DhPoc.CoinSecurity.real_rollBound',
    'DhPoc.CoinSecurity.ideal_rollBound',
    'DhPoc.CoinSecurity.five_samplingError_negligible',
    'DhPoc.CoinSecurity.advantage_negligible',
    'DhPoc.CoinSecurity.session_secure_isPPTBy',
    'DhPoc.CoinResources.queryPolynomial_eval',
    'DhPoc.CoinResources.isPPTBy_coinBound',
    'DhPoc.CoinResources.isPPTBy_parameterBound',
    'DhPoc.CoinResources.games_polynomial_coinBound',
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
