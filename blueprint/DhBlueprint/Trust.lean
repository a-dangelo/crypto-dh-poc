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

The main theorem assumes `x86_64-no-tables` and a standard-DDH bound for the
explicit encoding reduction. Its axiom closure is `propext`, `Classical.choice`,
`Quot.sound`, `RustAx.core`, and `RustAx.subtle`. The sampling and hybrid lemmas
use only the first three. Concrete primitive correctness is proved from the
pinned BAIF development. Selected Rust runtime contracts remain axioms.

The trusted pipeline includes Charon, Aeneas and its models, Lean's kernel,
and the pinned definitions and contracts. The program includes the upstream
translation patches. Equivalence to unpatched dalek is outside the checked
chain. The older `ristretto255-dh 0.3.0` implementation is a differential-test baseline.

# Scope of the security statement

The [Signal blueprint's implementation bridge](https://github.com/a-dangelo/signal-security-blueprint/blob/83d448ba42558abd6f196a54b5c7e4d5e2615f16/content/report.md#L235-L329)
is instantiated here for one completed honest passive exchange.
{bpref "session_refinement"}[Session refinement] proves successful execution
for every pair of raw inputs. The two native game equalities preserve the
adversary and the input laws without conditioning. The sampling comparison
then accounts for the wide-reduction bias explicitly.

For a fixed adversary $`A`, the theorem assumes a DDH bound for $`R_A`.
It contains no PPT predicate, charged cost semantics, or theorem that the
encoding reduction preserves an efficient adversary class. The reduction
performs three canonical encodings and one call to $`A`; those costs remain
to be justified in a resource-bounded corollary. This is the
[resource condition](https://github.com/a-dangelo/signal-security-blueprint/blob/83d448ba42558abd6f196a54b5c7e4d5e2615f16/content/report.md#L89-L102)
identified in the Signal blueprint.

The curve and 512-bit tapes are fixed. There is no parameterized family of
implementations or negligibility theorem. The term $`2^{-260}` is a concrete
statistical loss. It supplies neither an asymptotic theorem nor a numerical
DDH-hardness estimate. A concrete security estimate therefore needs a
justified DDH bound $`\varepsilon` for the relevant adversary resources.
The Signal blueprint's
[asymptotic implication](https://github.com/a-dangelo/signal-security-blueprint/blob/83d448ba42558abd6f196a54b5c7e4d5e2615f16/content/report.md#L104-L170)
requires separate parameterization, efficiency and negligibility arguments.

Caller entropy is ideal. The proof does not cover an operating-system RNG,
compiler or machine code, timing leakage, or erasure. Authentication, adaptive
corruption, multiple sessions, candidate-key selection and key-release security
require other games. The ideal challenge is an encoded group element.
The proof establishes no KDF or uniform-byte-key claim.

# Evidence and reproduction

The original extraction and linkage evidence is retained with its recorded
hashes. The current sources have revised comments and separate audit/regression
scripts. A [fresh cloud replay](source/blueprint/verification/current-source-replay.json)
checks both Lean libraries, matches all 22 concrete and 16 generic axiom closures,
and preserves four regressions. It does not repeat Rust extraction or native execution.

The current standard-DDH theorem's local import path has 1,178 Lean lines,
including 250 generated lines. The largest retained module has 195 lines.
These counts exclude external libraries and this documentation.

[Current source manifest](source/manifest.json) ·
[Current axiom audit](source/blueprint/verification/current-concrete-axioms.log) ·
[Historical proof report](source/concrete/evidence/concrete-proof-report.json) ·
[Reproduction instructions](source/README.md)

# Provenance

Galois's PQXDH development uses per-party simulation and experiment transport
under explicit primitive-model hypotheses. This example follows that direction
for a straight-line DH session and instantiates the primitive boundary with
the selected BAIF dalek proofs.

[The pinned Galois argument](https://github.com/GaloisInc/libsignal-docs-and-models/blob/e82e566ff4f1db69b2638c5813249a4d4497b14f/PQXDH/Aeneas/Full/UAKE/SecurityLemmas.lean#L640-L723)
is provenance for the architecture. This PoC does not reprove PQXDH or
production libsignal fidelity.

The paired-source renderer adapts
[the supplied declaration template](https://github.com/a-dangelo/scratchpad/tree/4b097e96e75f996d1228621bfc4b353aa803ed96/verso-blueprint-declarations).
The editable documentation was reconstructed from the persisted website and
source snapshot. The earlier documentation Git history was not recovered.
