#!/usr/bin/env python3
"""Reject accidental proof imports from the Diffie–Hellman project."""
from pathlib import Path
import re
root = Path(__file__).resolve().parents[1]
for dirname in ('lean',):
    for path in (root / dirname).rglob('*.lean'):
        if '.lake' in path.parts:
            continue
        text = path.read_text()
        assert not re.search(r'^\s*(?:public\s+)?import\s+(?:all\s+)?(?:DhPoc|Concrete|DhBlueprint)(?:\.|\s|$)', text, re.M), path
        assert not re.search(r'\b(?:sorry|admit)\b', text), path
print('Schnorr proof has no DH imports or proof placeholders.')
