# Schnorr VersoBlueprint

Edit `SchnorrBlueprint/Blueprint.lean`. It imports only the Schnorr proof and
Verso packages. `SchnorrBlueprint/Code.lean` contains the local declaration
renderer, adapted from the checked paired renderer in the earlier prototype.
Its source-window, spelling, and signature checks are retained. It has no
runtime dependency on that prototype.

The renderer's earlier source is `verso-blueprint-declarations` from
`a-dangelo/scratchpad` at `4b097e96e75f996d1228621bfc4b353aa803ed96`.
It displays imported declarations rather than hand-copied proof excerpts.

1. Prepare the Schnorr Lean dependencies as described in `../README.md`.
2. Run `lake exe cache get` to fetch the proof-library cache. Keep the committed manifest.
3. Run `bash scripts/build.sh`.
4. Serve `_out/site/html-multi/` locally to inspect the result.

The build compiles the proofs, audits endpoint axioms, compiles and renders
the blueprint, prepares a
local source snapshot, runs the VersoBlueprint checker, and checks local links
and declaration panels. The output includes source and is for local review.
No publication or deployment is configured.

For optional local browser checks, install Playwright and Chromium, then run
`python3 scripts/browser-qa.py`. It checks desktop and narrow viewports and
writes screenshots under `_out/qa/`. This does not publish or open an external service.
