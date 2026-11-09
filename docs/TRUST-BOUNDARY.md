# Exact claim and trust boundary

## Selected program and attack model

The final target is `concrete/rust/poc_dh.rs`, compiled with the pinned BAIF dalek 5.0.0 source after its translation patches. The configuration is serial x86_64 without precomputed tables, with the `alloc` and `zeroize` features. Precomputed tables are disabled.

The protocol is one honest, passive Diffie–Hellman session. Alice and Bob receive raw 64-byte secrets. Each sends a canonical 32-byte public encoding. Agreement parses the peer's bytes and returns an optional 32-byte shared encoding. Invalid encodings return `None`. The attacker sees both public encodings and one challenge encoding.

The theorem proves that honest encodings are accepted and both local keys agree. It includes zero secrets; it does not silently exclude them. It does not cover an attacker who modifies messages.

## Extraction and source correspondence

The script copies the pinned Rust workspace, applies its upstream translation patches, adds the wrapper, and performs the upstream four-target extraction. The patches are part of the selected verified program. Equivalence to the unpatched program is not proved here.

The script checks that the patches really applied. A separate comparison checks every original generated type and function/implementation declaration against the pinned proof repository. It ignores block comments only, not executable code, line comments, or whitespace. All 129 type blocks and 2,731 function/implementation blocks match. The only new declarations are the protocol wrappers.

The generated adapter is copied as exact declaration blocks from that output. The original primitives are imported from the matched proof source. The linkage theorems identify the extracted wrapper bodies with the proved compositions by definitional equality. The security games call the actual extracted `Curve25519Dalek.poc_dh.session`.

The extraction emits inherited warnings about two `Step` trait fields absent from Aeneas's model. It exits successfully. The selected theorem closure is audited separately; no admitted proof or additional primitive assumption occurs in that closure.

## Functional proof

The model uses the Edwards L-torsion subgroup and scalar field `ZMod L`. Canonical public/key encodings are computed directly from Ristretto encoding, not through a discrete-log inverse.

Decoding need not recover the same internal Edwards representative. The proof uses the Ristretto relation, proves that scalar multiplication preserves that relation, and then proves equality of the canonical encodings.

The checked primitive proofs cover wide scalar reduction, basepoint multiplication, decompression, scalar multiplication, compression, and byte output. Both fields of the concrete `RawPrimitiveModel` are proved.

`native_session_refines` proves the complete successful result of the actual extracted session. Non-success branches remain explicit in the games and are proved unreachable for honest inputs. The proof does not condition on successful runs.

## Probability and security

`nativeAdvantage_eq` retains arbitrary raw-secret samplers exactly. It compares the native games with a separately defined sampled-DDH game over the same raw distributions and scalar decoder. It asserts no security for an arbitrary distribution by itself.

`uniformWide` selects a uniform integer below `256^64` and converts it to 64 little-endian bytes. The proved `uniformWide_decode` identifies its exact decoded scalar: the sampled integer reduced modulo L.

`wideAdvantage_le` instantiates both parties with this ideal wide sampler. Its hypothesis is a bound on wide-sampler DDH for the explicit encoding reduction. This is a separate premise from ordinary uniform-scalar DDH. The exact wide-sampler theorem remains available.

The later `wideAdvantage_le_of_standardDDH` proves the standard-DDH corollary. Let `N = 2^512` and `r = N mod L`. The proof counts every event after modular reduction and proves TV distance at most `r/N` from uniform `ZMod L`. It then replaces two independent public scalars in each of the real and random branches. The random challenge is already uniform and does not change. VCVio's `boolDist` is the absolute difference of acceptance probabilities, so the four replacements cost at most `4r/N`. Exact Lean arithmetic proves `4r/N < 2^-260`. A supplied standard-DDH bound `ε` therefore gives native advantage at most `ε + 2^-260`.

The counting and hybrid lemmas use only Lean's standard logical axioms. No sampler-distance hypothesis remains. The result uses an upper bound, not a proof of the sharp exact TV formula. The adversary interface is VCVio's `ProbComp`; it does not add an `OptionT` adversary failure model.

The ideal challenge is an independent uniform scalar multiple of the generator, canonically encoded and wrapped in `some`. No claim about a uniform 32-byte string or a KDF follows.

## Explicit premises and full axiom closure

The equality selects the compilation target with `Aeneas.Std.target = "x86_64-no-tables"`. The original wide bound assumes its displayed sampled-DDH inequality. The standard corollary instead assumes the displayed standard uniform-scalar DDH inequality. Concrete primitive correctness is not a remaining theorem parameter.

The concrete theorem closure contains exactly:

- `propext`, `Classical.choice`, and `Quot.sound`, Lean's standard logical axioms.
- `RustAx.core`, the pinned backend's bundled functional contracts for array construction, Result mapping, integer ceiling division, mutable array iteration, and identity borrowing.
- `RustAx.subtle`, bundled functional contracts for valid Choice values, equality, conditional selection/assignment/swap, and CtOption construction.

The exact declarations are [RustAx.core](https://github.com/Beneficial-AI-Foundation/curve25519-dalek-fork/blob/95b5831c63ff1c5f6287bd3a77569412a9afdbfb/curve25519-dalek/lean/Curve25519Dalek/FunsExternal.lean#L91-L157) and [RustAx.subtle](https://github.com/Beneficial-AI-Foundation/curve25519-dalek-fork/blob/95b5831c63ff1c5f6287bd3a77569412a9afdbfb/Subtle/Contract.lean#L404-L428). Each axiom asserts a bundle; the audit does not claim every bundled field is used by the endpoint.

There is no `sorryAx`, `RustAx.alloc`, or `RustAx.zeroize` in the endpoint closure. A clean audit does not prove the two Rust contract bundles themselves.

## Remaining trust and non-goals

The trusted pipeline includes Charon, Aeneas and their standard models, Lean's kernel, the matched upstream definitions and contracts, and host/toolchain integrity. The result concerns Aeneas functional semantics, not compiled machine-code semantics.

Native smoke tests run the same patched source and check 128 deterministic sessions against an older implementation, plus rejection of a malformed public encoding. These are additional tests, not proofs of compiler correctness or source-patch equivalence.

The work does not verify an operating-system RNG, timing/cache leakage, secret erasure, fault resistance, authentication, multiple sessions, a KDF, or a formal running-time model. A meaningful cryptographic application still needs its stated hardness and resource assumptions.

## Earlier prototype

The `lean/` package contains the initial generic proof and an intentionally insecure `ZMod 7` example. Its clean standard-axiom audit demonstrates that the generic contracts are explicit hypotheses. It is not the final native implementation theorem. The `rust/native/` baseline uses crates.io `ristretto255-dh` 0.3.0 and dalek 2.1.3, not the final patched dalek 5.0.0 target.
