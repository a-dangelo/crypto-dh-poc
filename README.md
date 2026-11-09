# A Rust-to-Lean security reduction for Ristretto Diffie–Hellman

This repository contains a Lean-checked security reduction for a coin-explicit
Rust implementation of one passive Ristretto Diffie–Hellman session. We connect
the Aeneas translation of a pinned, patched dalek backend to VCVio security games,
then bound the sampling loss needed to apply standard DDH. The concrete
arithmetic and encoding contracts are proved from the pinned BAIF development.

Blueprint deployment target: [a-dangelo.com/crypto-dh-poc/](https://a-dangelo.com/crypto-dh-poc/).

## Main result

Assume the configuration `Aeneas.Std.target = "x86_64-no-tables"`. Each party
independently samples an ideal 512-bit integer and reduces it modulo the scalar
order `L`. A standard uniform-scalar DDH bound `ε` for the explicit encoding
reduction then gives native real/ideal distinguishing advantage at most
`ε + 2^-260`.

The relevant statements are:

- [`DhConcrete.nativeAdvantage_eq`](concrete/Concrete/Native.lean): exact equality
  with sampled-DDH advantage for arbitrary independent caller-supplied raw-secret
  distributions. This equality alone asserts no security for those distributions.
- [`DhConcrete.wideAdvantage_le_of_standardDDH`](concrete/Concrete/Standard.lean):
  the standard-DDH corollary for two independent ideal wide samplers.
- [`DhConcrete.wideAdvantage_le`](concrete/Concrete/Wide.lean): the earlier exact
  bound under a separate wide-sampler DDH premise.

To obtain the standard-DDH corollary, we account for the bias of reduction modulo
`L`. Let `r = 2^512 mod L`. The event-counting argument bounds the total variation
distance from uniform scalar sampling by `r/2^512`. Two scalar replacements in
each game branch cost at most `4r/2^512 < 2^-260`. The proof uses this upper bound.
The sharp formula for the exact distance is not proved here.

The ideal challenge is `some` of a canonical encoding of an independent uniform
scalar multiple of the generator. The result makes no claim about a uniform
32-byte key or a KDF. Advantage is VCVio's absolute difference of acceptance
probabilities.

## Program and proof structure

The selected program is [`concrete/rust/poc_dh.rs`](concrete/rust/poc_dh.rs) with
BAIF's pinned dalek 5.0.0 source and its translation patches. The configuration
uses the serial x86_64 backend without precomputed tables. The wrapper takes
64-byte secrets, sends canonical 32-byte public values, and returns an optional
shared encoding. Invalid peer encodings return `None`.

The proof proceeds through four stages:

1. Charon and Aeneas extract the wrapper together with the patched backend.
2. A declaration comparison checks the extracted backend against the pinned
   proof repository. All 129 type blocks and 2,731 function/implementation blocks
   match. The [generated adapter](concrete/Concrete/GeneratedAdapter.lean) is an
   exact slice of this extraction.
3. Lean proves the concrete public-value and agreement contracts from BAIF's
   arithmetic and codec proofs. Definitional equalities link these compositions
   to the generated wrappers. `native_session_refines` proves the complete
   successful output of the extracted session for honest inputs.
4. The VCVio real and ideal games execute the extracted
   `Curve25519Dalek.poc_dh.session`. Exact game transport, the sampling-distance
   bound, and four replacements yield the standard-DDH corollary.

The final development is in [`concrete/`](concrete/README.md). The earlier generic
prototype remains in `rust/` and `lean/`. The
[linkage report](concrete/evidence/linkage-comparison.json) records the declaration
comparison, and the [axiom audit](concrete/evidence/axioms.log) records the complete
theorem dependency closures.

## Assumptions and scope

The endpoint depends on `propext`, `Classical.choice`, and `Quot.sound`, together
with `RustAx.core` and `RustAx.subtle`. The latter two supply functional contracts
for selected Rust core and subtle operations. Concrete primitive correctness is
proved. The runtime contract bundles remain assumptions.

The result concerns the selected patched program in Aeneas functional semantics.
The trusted pipeline includes Charon, Aeneas and its models, Lean's kernel, the
pinned upstream definitions and contracts, and host/toolchain integrity.
Equivalence to unpatched dalek or the older `ristretto255-dh` release is not proved.
Native differential tests use the older implementation only as an additional
check.

The wide sampler models ideal caller entropy. The development does not verify
an operating-system RNG, the Rust compiler, machine code, timing or cache
behavior, or secret erasure. The security claim covers one honest passive session
and excludes authentication, active attacks, multiple sessions, and a formal
running-time model. The supplied DDH hardness bound remains a premise. See the
[trust boundary](docs/TRUST-BOUNDARY.md) for the precise contracts and exclusions.

## Reproduction

The full proof and extraction recipe targets Linux x86_64.

1. Install Git, Python 3, curl, tar, sha256sum, elan and rustup.
2. Run `scripts/bootstrap-lean.sh`, then `scripts/bootstrap-concrete.sh` to obtain
   the pinned dependencies.
3. Run `scripts/check-concrete.sh`. This regenerates extraction, checks linkage,
   builds the concrete proofs, audits axioms, and runs native smoke tests.
4. Run `scripts/check-generic.sh` with the November Aeneas toolchain to replay the
   earlier generic prototype, or `scripts/check.sh` to run both.

For a proof iteration after extraction, use
`scripts/check-concrete.sh --proof-only`. This mode does not regenerate extraction.
The separate [Blueprint build instructions](blueprint/README.md) describe how to
build the editable documentation with the committed dependency manifests.

## Evidence and provenance

The repository was recovered from a persisted source snapshot and starts a new
Git history. The recorded original revision is
`a27d45ad02331a96279032a11872d6ec7af47860`. Its Git objects were not recovered.
The 67 original source and evidence contents remain hash-verifiable. The original
README is preserved at [`docs/recovered/README.md`](docs/recovered/README.md),
separate from this revised introduction. [RECOVERY.md](RECOVERY.md) documents the
archive, path mapping, and verification limits.

The [concrete proof report](concrete/evidence/concrete-proof-report.json) records
the original full extraction, later proof-only replay, native tests, pins, source
hashes, and theorem premises. The [extraction manifest](concrete/evidence/extraction-inputs.json)
binds the extraction to its Rust wrapper, patch set, and output hashes. Those
checks ran in a prepared cloud workspace.
The original full-extraction bootstrap was not independently replayed from an
empty machine.

A [separate cloud replay](blueprint/verification/cloud-replay.json) rebuilt the
concrete proofs and matched all 22 audited dependency closures during the
Blueprint reconstruction. It did not repeat Rust extraction or native tests.
[Documentation QA](blueprint/verification/QA.md) records the build, source-panel,
link, and browser checks. The [line-count report](line-counts.json) excludes the
external arithmetic libraries and the Blueprint.
