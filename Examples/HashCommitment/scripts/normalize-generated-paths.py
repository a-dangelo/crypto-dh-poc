#!/usr/bin/env python3
"""Normalize only Cargo registry path prefixes in generated source comments.

Aeneas records absolute Cargo cache paths. Replace the prefix through
`registry/src/` with `/cargo/registry/src/`. No Lean term is changed.
"""
import pathlib
import re
import sys
root = pathlib.Path(sys.argv[1])
for path in root.glob('*.lean'):
    text = path.read_text()
    text = re.sub(r"(?m)^(    Source: ')[^'\n]*?/registry/src/", r"\1/cargo/registry/src/", text)
    path.write_text(text)
