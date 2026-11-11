> This is a chapter library in the [shared book](../README.md). Build and publish from `docs/`, not this directory.

# Schnorr VersoBlueprint

Edit `SchnorrBlueprint/Blueprint.lean`. It imports only the Schnorr proof and
Verso packages. `SchnorrBlueprint/Code.lean` contains the local declaration
renderer, adapted from the checked paired renderer in the earlier prototype.
Its source-window, spelling, and signature checks are retained. It has no
runtime dependency on that prototype.

The renderer's earlier source is `verso-blueprint-declarations` from
`a-dangelo/scratchpad` at `4b097e96e75f996d1228621bfc4b353aa803ed96`.
It displays imported declarations rather than hand-copied proof excerpts.

Build, browser QA, and publication are provided by the [shared book](../README.md).
Run its commands from the repository root. The source-inclusive review output is
`docs/_out/site/html-multi`; the publication output is `docs/_out/site/pages-public`.
The shared book checks these proofs with the DH-pinned Aeneas Lean runtime, while
`Examples/Schnorr` retains its independent extraction and proof build.
