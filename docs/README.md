# Verified cryptography examples

One VersoBlueprint book, with chapters for Diffie–Hellman, interactive Schnorr,
and hash commitment.
The book owns navigation, cross references, and a combined dependency graph.
Source packages stay separate in `../Examples/DH`, `../Examples/Schnorr`, and
`../Examples/HashCommitment`.

## Build

On Linux x86_64, install Git, Python 3 and official elan, then run from the repository root:

```sh
elan toolchain install leanprover/lean4:v4.35.0
bash docs/scripts/bootstrap.sh
bash docs/scripts/build.sh
python3 docs/scripts/export-public.py --repository-revision "$(git rev-parse HEAD)"
```

The source-inclusive review build is `docs/_out/site/html-multi`. The publication output is
`docs/_out/site/pages-public`. Publication keeps declaration excerpts and hover data;
full source and evidence links target the exact repository revision.
The export does not itself deploy anything.

The build verifies the original DH snapshot, replays the current DH proofs and axiom
closures, compiles all chapters, audits the examples in the shared Lake environment,
and checks source excerpts, local links and hovers. A fresh validated DH replay may
be reused by setting `DH_REPLAY_DIRECTORY` to its evidence directory.

Fresh shared-runtime DH and Schnorr audit logs are kept in
`docs/_out/shared-runtime-audit/`, separately from historical evidence.
The new example records its shared audit in
`Examples/HashCommitment/evidence/shared-audit.json`. This record references the
standalone manifest without claiming that the documentation build reran extraction.

## Runtime boundary

The independent examples retain their own extraction pins. Schnorr extraction used
Aeneas `nightly-2026.11.08-c5eb4a2`; DH uses commit
`de16f3cf877976e966906dc890f63dcb418884fa`. This shared book uses that base with the hash-commitment example’s explicit
probabilistic-effect patch, from `Examples/HashCommitment/vendor/aeneas`.
The independent DH and Schnorr pins and historical evidence remain unchanged.
The shared build checks compatibility with the patched runtime; it does not
assert that different Aeneas releases or extraction backends are equivalent.
The hash-commitment chapter distinguishes generated code, the ideal RNG
interpretation, and the hash-refinement assumption.

## Add a chapter

Keep program and proof material in `Examples/<Name>`. Put its documentation library
in `docs/<Name>`, add the library to `docs/lakefile.lean`, and include its blueprint in
`ExamplesBlueprint/Blueprint.lean`. Use unique blueprint labels and the
`source/<Name>/` source-link namespace. Extend source preparation, axiom auditing,
and source-link checks for the new chapter. Keep the graph and summary at book level.

For browser QA, install Playwright and Chromium/Chrome and run
`python3 docs/scripts/browser-qa.py`. It checks the public export at desktop and
narrow widths under `/crypto-dh-poc/`. Use `--site PATH` for another build and
`BLUEPRINT_BROWSER=/path/to/browser` to select the browser. The JSON report and
named screenshots are written to `docs/_out/qa` for CI artifact upload.
