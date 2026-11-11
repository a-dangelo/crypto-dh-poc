# Interactive Schnorr prototype

A small Rust prover and verifier, extracted to Lean with Charon and Aeneas.
The proof connects the extracted program to VCVio's Schnorr Σ-protocol.
The editable VersoBlueprint pairs mathematical statements with imported Lean
source, including proof bodies and type hovers.

## Start here

- [`rust/src/lib.rs`](rust/src/lib.rs): the `Group` trait and deterministic protocol.
- [`rust/native/src/lib.rs`](rust/native/src/lib.rs): executable dalek Ristretto
  adapter and tests; its primitive contracts are not proved.
- [`lean/Schnorr/Generated/`](lean/Schnorr/Generated/): generated Aeneas translation.
- [`lean/Schnorr/Refinement.lean`](lean/Schnorr/Refinement.lean): arithmetic contracts,
  arbitrary-input verifier refinement, completeness, and special soundness.
- [`lean/Schnorr/Security.lean`](lean/Schnorr/Security.lean): sampled Rust execution,
  exact transcript transport, and perfect honest-verifier zero-knowledge.
- [`lean/Schnorr/Randomness.lean`](lean/Schnorr/Randomness.lean): one oracle program,
  stateful extracted RNG interpretation, and a separate ideal interpretation.
- [`../../docs/Schnorr/SchnorrBlueprint/Blueprint.lean`](../../docs/Schnorr/SchnorrBlueprint/Blueprint.lean):
  editable mathematical exposition and theorem dependency graph.
- [`scripts/extract.sh`](scripts/extract.sh): extraction entry point.

This directory has its own Rust crate, Lean package, and pinned dependencies.
It does not import the DH prototype. The shared book lives in `../../docs/`,
with this example's chapter under `../../docs/Schnorr/`.

## Mathematical statement

Let `F` be a sampleable field, `G` a sampleable additive commutative group with
an `F`-module structure and decidable equality, and `g : G`. The public
statement is `pk = sk • g`. The nonce `r` and challenge `c` are independent
ideal samples in `ProbComp`.

`PrimitiveModel` assumes successful arithmetic calls on every value of the
native scalar and point types. Decoding an encoded mathematical value returns
that value; native representations need not be unique.
Under these assumptions:

1. `verify_accepts_iff` characterizes verification for arbitrary native inputs,
   including inputs that an honest prover did not generate.
2. `honest_complete` proves acceptance for every honest nonce and challenge.
3. `special_soundness` extracts `(z₁ - z₂) * (c₁ - c₂)⁻¹` from two accepting
   transcripts with the same commitment and distinct decoded challenges.
4. `rustTranscript_eq_encodedReal` identifies the sampled extracted prover
   with the encoded VCVio real experiment as programs.
5. `perfect_hvzk` proves equality in distribution with a simulator that uses
   only the public statement. Observations retain the complete Aeneas `Result`.

These are conditional protocol theorems, not a closed theorem for dalek.
No running-time bound is proved for arithmetic, representation maps, the
extractor, or the simulator. Perfect HVZK denotes exact transcript-distribution
equality here, without a proved efficiency bound for a concrete simulator.
A concrete implementation must discharge every `PrimitiveModel` field.
The primitive contracts cover every native input, not only values produced by
the encoders. They require outputs equal to the chosen `M.point` or `M.scalar`
encoding, not just correct decoded values. A future projective or dalek backend
may need normalization or a relation-based refinement. The tested Ristretto
adapter is not known to satisfy this exact-output model.

## Randomness boundary

The security endpoint receives the nonce and challenge explicitly. A separate
`ScalarRng` trait and `commit_random` wrapper expose a stateful RNG call.
The oracle interpretation connects this extracted state transition to the
protocol sampling effect. It does not identify the runtime law with ideal
`ProbComp` sampling. A monad lift establishes no sampling law. This prototype has no claim about uniform-byte decoding,
entropy quality, reseeding, or independence of outputs from a real generator.

`messages` computes both prover messages from an explicit challenge. A live
interactive protocol must send the commitment before receiving that challenge.
Completeness, special soundness and honest-verifier zero-knowledge do not
establish Fiat–Shamir signature security, EUF-CMA, malicious-verifier
zero-knowledge, wire parsing, compiled behavior, or side-channel resistance.

## Build and inspect

Use Linux x86_64 with official elan and rustup. The bootstrap prepares pinned
Lean `v4.35.0`, proof, and extraction dependencies. From this directory:

```sh
bash scripts/bootstrap.sh
bash scripts/check.sh
cd ../../docs
bash scripts/bootstrap.sh
bash scripts/build.sh
```

`scripts/check.sh` runs Rust tests, a fresh extraction comparison, the Lean
build, a strict axiom audit, and import-isolation checks. Use `--proof-only`
to skip Rust tests and extraction comparison.

The documentation build requires Python 3. It builds the proof and audits
endpoint axioms before rendering.
It writes `_out/site/html-multi/`, with a local source snapshot and SHA-256
manifest. No script publishes this output. Consult the extraction script for
its separate Rust and Aeneas tool requirements. A successful documentation
build does not repeat extraction or verify a native RNG.

VCVio is pinned at `88efe9715a9fa9e7d89635c38cf70259836766c2`.
Aeneas extraction uses release `nightly-2026.11.08-c5eb4a2`.
VersoBlueprint is pinned at `4943d3335ffa9221a39949e60836a8ad5dc2a456`.
