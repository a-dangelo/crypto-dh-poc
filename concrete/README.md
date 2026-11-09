# Concrete Rust → Aeneas → Lean → VCVio DH proof

**Main theorems:** `DhConcrete.nativeAdvantage_eq` in `Concrete/Native.lean`
and `DhConcrete.wideAdvantage_le_of_standardDDH` in `Concrete/Standard.lean`.
The earlier exact wide-sampler bound remains in `Concrete/Wide.lean`.
The real and ideal games both call the extracted Rust `poc_dh.session`.
The proof discharges the native primitive contracts using the pinned BAIF dalek
proofs. It is separate from the small generic proof package in `../lean`.

## What the theorem says

For the explicitly selected `x86_64-no-tables` target, the native session's
real/ideal distinguishing advantage equals sampled-DDH advantage for exactly the
caller's raw-secret distributions. The companion `nativeAdvantage_le` transports
an assumed sampled-DDH bound to the native session.

The equality has one explicit configuration premise:
`Aeneas.Std.target = "x86_64-no-tables"`.
The bound also has the stated sampled-DDH assumption. There are no remaining
primitive-correctness hypotheses. The raw samplers and adversary are universally
quantified. The ideal challenge is a canonical encoding of an independent
uniform scalar multiple of the generator, wrapped in `some`.

The standard-DDH corollary retains the wide-byte sampler and bounds its
distance from uniform scalar sampling. For `r = 2^512 mod L`, the proved bound
is `r/2^512`. Two independent scalar replacements in each game branch cost
at most `4r/2^512 < 2^-260`. Thus a standard DDH bound `ε` implies native
advantage at most `ε + 2^-260`. This is an upper bound, not the sharp TV formula.

The result does not establish authentication, active-attack security, side-channel security,
a KDF, an asymptotic security bound, or uniform 32-byte keys.

## Proof layers

- `Concrete/Algebra.lean`: Edwards L-torsion subgroup over `ZMod L`, basepoint,
  and the Ristretto relation needed when decoding a public key.
- `Concrete/Bytes.lean`: fixed-width little-endian encoding using 32 base-256
  digits; numeric roundtrip and byte-array injectivity.
- `Concrete/Wire.lean`: canonical Ristretto encoding into actual 32-byte arrays.
- `Concrete/Primitives.lean`: helper compositions of extracted dalek primitives,
  proved using the existing BAIF primitive specifications.
- `Concrete/Model.lean`: concrete `RawPrimitiveModel`, with both contracts proved.
- `Concrete/GeneratedAdapter.lean`: mechanically sliced actual Aeneas output.
- `Concrete/Native.lean`: definitional links to extracted wrappers, target
  dispatch, actual extracted-session correctness, and native security games.
- `Concrete/Sampler.lean`: explicit uniform 512-bit tape and exact scalar reduction.
- `Concrete/Wide.lean`: the native security endpoint instantiated with that sampler.
- `Concrete/ModuloSampling.lean`: total variation bound from quotient and remainder counts for arbitrary events.
- `Concrete/SamplingHybrids.lean`: four replacements in VCVio's absolute acceptance-probability distance.
- `Concrete/SamplingError.lean`: exact arithmetic proves the loss is below `2^-260`.
- `Concrete/Standard.lean`: standard uniform-scalar DDH corollary for the native game.
- `../scripts/check-concrete-axioms.lean`: transitive axiom dependencies and endpoint statements.

The helper compositions are handwritten, but their equality to the actual
extracted target-specific Rust wrappers is proved by `rfl`. The native security
games run the actual generated session, not those handwritten compositions.
The adapter slice is accepted only after comparing every pre-existing generated
backend declaration with the pinned proof source. The comparison ignores only
block comments; it preserves executable text and whitespace. See `evidence/linkage-comparison.json`.

## Selected Rust target

The selected program uses the pinned BAIF dalek 5.0.0 source with its translation patches,
plus `rust/poc_dh.rs`. Equivalence to unpatched dalek is outside the checked chain.
The executable smoke tests use the same patched source.

## Trust boundary

The native theorems' full axiom closure is:
`propext`, `Classical.choice`, `Quot.sound`, `RustAx.core`, `RustAx.subtle`.
The last two are runtime and library assumptions from the BAIF development.
The proof uses no `sorry` or additional axiom.

The result concerns the Aeneas semantics. It relies on the extraction toolchain,
the pinned upstream definitions/contracts, and the normal Lean kernel trust
boundary. Native smoke tests are separate executable checks, not a proof of the
Rust compiler or machine code. The original generic proofs are rebuilt under the
exact Aeneas dependency in this package's independent output cache.

## Reproduce

From the repository root:

1. Run `scripts/bootstrap-lean.sh`.
2. Run `scripts/bootstrap-concrete.sh`.
3. Run `scripts/check-concrete.sh`.

The full check regenerates extraction. For a later proof iteration, use `--proof-only`.

Lean is pinned to 4.35.0 and Aeneas to `nightly-2026.10.30-de16f3c`.
EllipticCurve is pinned to `4015c7cfab714640e77500bdbde6e64face3fbaa`.
The upstream dalek proof is `../vendor/dalek-proof` at the revision recorded in
the project's provenance records. `evidence/final-build.log` records the successful build;
`evidence/concrete-proof-report.json` summarizes the checked endpoint and premises.
