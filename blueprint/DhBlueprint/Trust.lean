import Verso
import VersoManual
import VersoBlueprint
import DhBlueprint.Code
import Concrete.Standard

open Verso.Genre Verso.Genre.Manual Informal

#doc (Manual) "Trust and provenance" =>
%%%
tag := "trust"
%%%

The final theorem assumes the selected target and a standard-DDH bound
for the explicit encoding reduction. Its axiom closure is
`propext`, `Classical.choice`, `Quot.sound`, `RustAx.core`, and
`RustAx.subtle`. The sampling and hybrid lemmas use only the first three.

The inherited Rust axioms specify selected core and subtle operations.
The extraction toolchain and Lean kernel remain trusted. The Rust source
includes the pinned upstream translation patches; equivalence to the
unpatched fork is outside the checked chain. The older
`ristretto255-dh 0.3.0` implementation is a differential-test baseline.

The scope is one passive session with ideal independent caller entropy.
It excludes an operating-system RNG proof, compiler or machine-code
verification, timing leakage, erasure, authentication, active or
multi-session attacks, and a KDF. The theorem states a concrete reduction
for an arbitrary `ProbComp` adversary; a resource-bounded hardness claim
must account for the reduction cost.

# Evidence and reproduction

The pinned report records 22 audited declarations, 23 source hashes and
27 translation-patch hashes. The preserved checks include a full
extraction, a later proof replay, and 128 native differential sessions.
A fresh-machine bootstrap was not independently replayed for that milestone.
A separate [cloud replay](source/blueprint/verification/cloud-replay.json)
rebuilds the recovered proof in 4,097 jobs and reproduces all 22 axiom
closures. It does not repeat extraction or native execution.

The final theorem's local import path contains 1,145 Lean lines:
895 handwritten and 250 generated. The audited modules contain 1,361 lines,
excluding six lines in import roots; the largest file has 195. These counts
exclude dependency libraries and this documentation.

[Proof report](source/concrete/evidence/concrete-proof-report.json) ·
[Axiom audit](source/concrete/evidence/axioms.log) ·
[Reproduction instructions](source/README.md) ·
[Source manifest](source/manifest.json)

# Provenance

Galois's PQXDH development uses per-party simulation and experiment
transport to transfer advantage under explicit primitive-model hypotheses.
This example follows that direction for a straight-line DH session and
instantiates the primitive boundary with the selected BAIF dalek proofs.

[The pinned Galois argument](https://github.com/GaloisInc/libsignal-docs-and-models/blob/e82e566ff4f1db69b2638c5813249a4d4497b14f/PQXDH/Aeneas/Full/UAKE/SecurityLemmas.lean#L640-L723)
is provenance for the architecture; this PoC does not reprove PQXDH or
production libsignal fidelity.

The paired-source renderer is adapted from
[the supplied declaration template](https://github.com/a-dangelo/scratchpad/tree/4b097e96e75f996d1228621bfc4b353aa803ed96/verso-blueprint-declarations).
This editable documentation was reconstructed from the persisted website
and audited source snapshot. The earlier documentation Git history was
not recovered.
