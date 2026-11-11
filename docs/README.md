# Verified cryptography examples

One VersoBlueprint book, with Diffie–Hellman first and interactive Schnorr second.
The book owns navigation, cross references, and a combined dependency graph.
Source packages stay separate in `../Examples/DH` and `../Examples/Schnorr`.

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
closures, compiles both chapters, audits Schnorr in the shared Lake environment,
and checks source excerpts, local links and hovers. A fresh validated DH replay may
be reused by setting `DH_REPLAY_DIRECTORY` to its evidence directory.

## Runtime boundary

The independent examples retain their own extraction pins. Schnorr extraction used
Aeneas `nightly-2026.11.08-c5eb4a2`; DH uses commit
`de16f3cf877976e966906dc890f63dcb418884fa`. This shared book explicitly uses the latter
Lean runtime. Both packages use the same VCVio and Mathlib pins. A successful book
build checks the Schnorr proofs again under that shared runtime; it is not a claim
that two full Aeneas releases are identical or that all extraction backends agree.

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
