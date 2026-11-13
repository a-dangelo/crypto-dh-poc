"""Shared chapter inventory for exact source and declaration-panel checks."""
from pathlib import Path
import re

DOC = Path(__file__).resolve().parents[1]
CHAPTERS = ('DH', 'Schnorr', 'HashCommitment')
TITLES = ('DH session in Rust', 'Interactive Schnorr in Rust', 'Hash commitment in Rust')


def expected_panels():
    """Count declared panels, not rendered panels, so missing output still fails."""
    counts = {}
    for chapter in CHAPTERS:
        files = list((DOC / chapter).glob('*Blueprint/*.lean'))
        counts[chapter] = sum(len(re.findall(r'^:::[A-Za-z]+Blueprint\.pair\s', p.read_text(), re.M))
                              for p in files)
    assert counts['DH'] == 33 and counts['Schnorr'] == 15, counts
    assert counts['HashCommitment'] > 0, counts
    return sum(counts.values())
