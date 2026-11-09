# A small end-to-end Rust → Aeneas → Lean → VCVio proof

**Checked result:** a standard-DDH security reduction for one passive Ristretto DH session, implemented in Rust with a pinned, proof-ready dalek backend.

The native real and ideal games execute the actual Aeneas translation of the Rust session. The concrete arithmetic and encoding contracts are proved, not left as parameters. The result retains explicit runtime assumptions, a fixed build configuration, and a named cryptographic hardness premise.

## Read these theorems first

- `DhConcrete.nativeAdvantage_eq`: exact reduction for arbitrary caller-supplied raw-secret distributions.
- `DhConcrete.wideAdvantage_le_of_standardDDH`: standard uniform-scalar DDH bounds the native advantage by `ε + 2^-260`.
- `DhConcrete.wideAdvantage_le`: the earlier exact bound under a separate wide-sampler DDH premise.

The standard-DDH corollary includes the sampling-distance proof. Each party independently samples an ideal 512-bit integer and reduces it modulo the scalar order `L`. This reduction is slightly biased. Lean bounds its total variation distance by `r/2^512`, where `r = 2^512 mod L`. Four game replacements cost at most `4r/2^512 < 2^-260`.

The proof uses this rigorous upper bound. It does not claim the sharp formula for the exact distance.

The ideal challenge is `some` of a canonical encoding of an independent uniform scalar multiple of the generator. It is not a uniform 32-byte key.

## The exact program

`concrete/rust/poc_dh.rs` contains the small coin-explicit Rust protocol. It uses BAIF's pinned dalek 5.0.0 source **with that project's translation patches applied**. The selected configuration is serial x86_64 without precomputed tables.

The proofs concern this patched program. They do not establish equivalence to unpatched dalek or to the old `ristretto255-dh` release. Native differential tests use that older implementation only as an additional check.

The first generic prototype remains in `rust/` and `lean/`. It explains the bridge with fewer details. The final concrete result is in `concrete/`.

## Proof path

1. The Rust wrapper takes 64-byte secrets, sends canonical 32-byte public values, and explicitly handles failed decoding.
2. Charon and Aeneas extract the wrapper together with the pinned backend.
3. A checked script compares every pre-existing generated backend declaration with the proof repository: 129 type blocks and 2,731 function/implementation blocks match.
4. Lean proves the concrete public and agreement contracts from existing BAIF arithmetic and codec proofs.
5. Lean links those compositions to the actual generated wrappers and proves the full native session output.
6. VCVio real and ideal games call that native session. Lean proves exact advantage equality for the actual scalar distribution.
7. An event-counting proof bounds the sampling bias. Four replacements give the standard-DDH corollary.

`concrete/Concrete/GeneratedAdapter.lean` is mechanically sliced from the actual extraction. It is not a handwritten model. `concrete/evidence/axioms.log` records the full theorem dependency closures.

## What remains trusted or outside scope

The endpoint depends on Lean's standard logical axioms plus `RustAx.core` and `RustAx.subtle`. These are explicit functional contracts for selected Rust core and subtle operations. They are not side-channel proofs.

The theorem also selects `Aeneas.Std.target = "x86_64-no-tables"`. The bound assumes the stated DDH hardness claim. The wide endpoint models ideal caller entropy; it does not verify an operating-system RNG.

The work does not verify the Rust compiler or machine code, authenticate peers, cover active or multiple-session attacks, prove timing security, or add a KDF. See [the trust boundary](docs/TRUST-BOUNDARY.md).

## Reproduce

1. Install Git, curl, elan and rustup on Linux x86_64.
2. Run `scripts/bootstrap-lean.sh`, then `scripts/bootstrap-concrete.sh` to obtain the exact dependencies.
3. Run `scripts/check-concrete.sh` for the final endpoint. It regenerates extraction, checks linkage, builds all concrete proofs, audits axioms, and runs native smoke tests.
4. Run `scripts/check-generic.sh` with the November Aeneas toolchain to replay the earlier generic prototype, or `scripts/check.sh` to run both.

For a proof-only iteration after extraction, use `scripts/check-concrete.sh --proof-only`. This mode does not claim a new extraction run.

The recorded checks ran in the prepared cloud workspace, not a newly empty machine.
The evidence includes a full extraction and a later proof-only replay.
An input manifest binds that extraction to its Rust wrapper, patch set, and output hashes.
The bootstrap recipes are pinned and syntax-checked; a fresh-machine bootstrap was not independently replayed.

The evidence report gives per-file hashes, line counts, pins, premises, and checks. The larger arithmetic libraries are dependencies and are not hidden inside the PoC's line count. The whole task runs in the cloud, with no Mac changes.
