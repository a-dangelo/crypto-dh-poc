#!/usr/bin/env python3
"""Check that probabilistic extraction retains repeated opaque monadic calls.

This focused syntactic regression complements the kernel-checked distribution
regressions. It is not a correctness proof for the translator.
"""
import pathlib
import re
import sys

def declaration(path, name):
    text = pathlib.Path(path).read_text()
    match = re.search(r'(?m)^def ' + re.escape(name) + r'\b', text)
    if not match:
        raise SystemExit(f'{path}: missing generated declaration {name}')
    end = re.search(r'(?m)^(?:def |/--|end )', text[match.end():])
    return text[match.start():match.end() + end.start()] if end else text[match.start():]

prob, ordinary = sys.argv[1:]
for name, expected in [('fresh_draws', 2), ('reused_draw', 1), ('branch_draw', 1)]:
    term = declaration(prob, name)
    actual = len(re.findall(r'\.fill_bytes\b', term))
    if actual != expected:
        raise SystemExit(f'{name}: expected {expected} fill_bytes calls, found {actual}')
    print(f'{name}: {actual} extracted fill_bytes call(s) retained')

for path, expected, mode in [(prob, 2, 'probabilistic'), (ordinary, 1, 'ordinary')]:
    term = declaration(path, 'duplicate_opaque')
    actual = len(re.findall(r'\.sample\b', term))
    if actual != expected:
        raise SystemExit(f'{mode}: expected {expected} opaque samples, found {actual}')
    if mode == 'probabilistic' and len(re.findall(r'←[^\n]*\.sample\b', term)) != 2:
        raise SystemExit('opaque samples were not retained as monadic calls')
    print(f'duplicate_opaque: {actual} monadic sample call(s) in {mode} mode')
for path, expected, mode in [(prob, 2, 'probabilistic'), (ordinary, 1, 'ordinary')]:
    term = declaration(path, 'unused_opaque')
    actual = len(re.findall(r'\.sample\b', term))
    if actual != expected:
        raise SystemExit(f'{mode}: unused opaque effect count {actual}, expected {expected}')
    print(f'unused_opaque: {actual} sample call(s) in {mode} mode')
print('Duplicate-call and unused-effect regressions passed.')
