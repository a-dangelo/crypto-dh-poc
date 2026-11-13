# Hash commitment with an effectful RNG

This example studies a Rust hash commitment whose RNG is passed by mutable reference. It separates three claims:

1. **Functional refinement:** the generated hash call computes a specified pure hash function. This is the explicit hypothesis `HashRefines`; no concrete hash implementation is verified here.
2. **Randomness refinement:** the extracted RNG dictionary is instantiated with ideal entropy effects. Its probability semantics samples fresh bytes, preserves the entire returned value, and composes with later computation.
3. **Binding:** VCV-io's hash-commitment reduction bounds binding advantage by keyed collision-resistance advantage. This does not establish collision resistance or hiding.

`CryptoRng` is a Rust marker trait, not a cryptographic proof. The ideal dictionary does not claim that an arbitrary seeded generator, operating-system RNG, or concrete generator has this distribution.

## Source and proof map

- `rust/src/lib.rs`: commitment, verification, and small entropy regression programs.
- `lean/HashCommitment/Generated/`: actual Aeneas output; never edited by hand.
- `lean/HashCommitment/Probability.lean`: interpretation of the actual interaction tree, including failure, divergence and exhausted fuel.
- `lean/HashCommitment/IdealRng.lean`: the ideal extracted dictionary and buffer laws.
- `lean/HashCommitment/Bridge/`: representation conversions and equalities connecting generated terms to finite witnesses.
- `lean/HashCommitment/Model/`: protocol-level sampling and the existing VCV-io commitment interface.
- `lean/HashCommitment/Security.lean`: honest generated execution and binding transfer.
- `lean/HashCommitment/Regressions.lean`: fresh, reused, branching and empty-buffer cases.
- `../../docs/HashCommitment/`: the corresponding chapter in the common Verso Blueprint book.

The finite witness is not a replacement implementation. Every claimed generated-code probability law requires an equality between the witness's Aeneas embedding and the actual generated term. Adequacy then relates the canonical interpretation to the witness's probability law. Sufficient fuel excludes cutoff; it does not condition away failures.

## Reproduction

Use Lean 4.35.0 and the revisions in `patches/toolchain.json`. The scripts record the patch and source identities. The patched extractor's opt-in probability mode preserves repeated and unused monadic calls; ordinary extraction remains unchanged.

```sh
cd Examples/HashCommitment
scripts/bootstrap.sh
scripts/extract.sh
scripts/check-extraction.sh
scripts/check.sh
scripts/audit.sh
```

`check-extraction.sh` regenerates into a temporary directory and compares the result with the checked-in generated source. It also checks the actual two-identical-call Rust regression. The evidence manifest records source identities; the replay scripts and logs record the commands. See `patches/README.md` for the runtime and extraction changes.

The shared book uses the patched runtime once, for all examples. DH and Schnorr retain their original standalone pins. The shared build separately audits all three examples against the patched runtime.

## Attribution and scope

The starting point is Marco Stronati's `toy-bridge` experiment at revision `5212ebba2f937765c7ed4d1fb52f3e46e10dcea9`. The protocol-model and representation files retain that experiment's structure. The explicit entropy effect, canonical bounded interpreter, mutable-buffer laws, generated-code regressions, and probability transfer are the additional work in this example. The keyed-CR reduction is reused from VCV-io, not reproved as a new cryptographic result.

Aeneas and Charon translation are part of the trusted toolchain. The checked Lean results concern the generated semantics, not a proof of the compiler, operating system, machine code, side-channel resistance, or a concrete hash/RNG implementation.

## Verification status

The full example check passed: Rust tests, extraction, clean regeneration comparison,
duplicate/unused-call regressions, the complete Lean build, and a 29-endpoint axiom
audit. The audit reports only Lean’s standard logical axioms. The common book also
builds with all three chapters under the patched runtime; its endpoint audits,
source excerpts, navigation, and review-export checks pass. Browser inspection
remains pending because Chromium cannot create its required local socket in the
validation environment. No remote CI run or deployment is claimed.

The Rust test dictionaries are deterministic fixtures, not cryptographic primitives
or evidence of RNG security. Exact upstream attribution appears in
[`evidence/upstream-source.json`](evidence/upstream-source.json). Publication also
requires review of upstream reuse terms: no licence was present in the inspected
toy-bridge source tree.
