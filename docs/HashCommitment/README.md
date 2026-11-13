# Hash-commitment chapter

This chapter belongs to the common VersoBlueprint book in `docs/`. Its independent
Rust program, generated Lean, proofs, extraction patch and reproduction evidence
belong to [`Examples/HashCommitment`](../../Examples/HashCommitment/README.md).

Build the common book with `bash docs/scripts/build.sh` after the bootstrap in
[`docs/README.md`](../README.md). Declaration cards import the checked Lean
commands, including proof bodies. They are not hand-copied summaries.

The local review output contains a hashed source snapshot under
`source/HashCommitment/`. The public exporter replaces these links with links to
the selected repository revision. It does not publish the source snapshot or
perform a deployment.

The chapter separates three objects: the generic extracted Rust program, an
ideal interpretation of its RNG operations, and a probabilistic protocol model.
The interpretation is not a verification of an operating-system RNG. Hash
refinement and collision resistance are explicit assumptions; no hiding theorem
is claimed.
