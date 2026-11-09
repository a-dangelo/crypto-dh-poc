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

This optional section records the trust boundary, scope, and provenance of
the preceding results.

The native theorem assumes `x86_64-no-tables` and a standard-DDH bound for the
explicit encoding reduction. Its axiom closure is `propext`, `Classical.choice`,
`Quot.sound`, `RustAx.core`, and `RustAx.subtle`. The sampling and hybrid lemmas
and parameterized results use only the first three. Concrete primitive correctness is proved from the
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

For a fixed adversary $`A`, the native theorem assumes a DDH bound for $`R_A`.
It contains no PPT predicate, charged cost semantics, or theorem that the
encoding reduction preserves an efficient adversary class. The reduction
performs three canonical encodings and one call to $`A`; those costs remain
to be justified for a concrete resource model. This is the
[resource condition](https://github.com/a-dangelo/signal-security-blueprint/blob/83d448ba42558abd6f196a54b5c7e4d5e2615f16/content/report.md#L89-L102)
identified in the Signal blueprint.

The native curve and 512-bit tapes are fixed. Its $`2^{-260}` term is a
concrete statistical loss. A concrete security estimate still needs a DDH
bound $`\varepsilon` for the relevant adversary resources.
The {bpref "parameterized_security"}[family theorem] separately makes the
group order, sampling width, DDH hypothesis and reduction closure explicit.
A corresponding native family requires refinement at every parameter.

For a polynomial-time interpretation, applications must justify efficient
parameter generation, polynomially bounded sampling width, and efficient
group operations and encodings. In the general class theorem, efficiency
predicates and reduction closure are explicit hypotheses. The
{bpref "ppt_security"}[strict-PPT theorem] derives closure from certified
polynomial encoding code and backend composition costs. A conventional
machine interpretation still requires backend adequacy, a unary parameter
representation and polynomial growth of other represented inputs. These are the
[asymptotic conditions](https://github.com/a-dangelo/signal-security-blueprint/blob/83d448ba42558abd6f196a54b5c7e4d5e2615f16/content/report.md#L104-L170)
identified in the Signal blueprint.

CryptHOL's [hashed ElGamal tutorial](https://isa-afp.org/browser_info/current/AFP/Game_Based_Crypto/CryptHOL_Tutorial.html)
proves a concrete bound and a separate asymptotic corollary that assumes
negligible advantage for the reduced adversary.

[Bao, Pan and Zeng, §1](https://eprint.iacr.org/2026/1980) discuss asymptotic
reduction loss and concrete tightness.
[Roy, Datta and Mitchell, §2](https://theory.stanford.edu/~jcm/papers/rdm-tgc-07.pdf)
formulate polynomial-time executions and negligible failure as the parameter grows.

Caller entropy is ideal. The proof does not cover an operating-system RNG,
compiler or machine code, timing leakage, or erasure. Authentication, adaptive
corruption, multiple sessions, candidate-key selection and key-release security
require other games. The ideal challenge is an encoded group element.
The proof establishes no KDF or uniform-byte-key claim.

# Evidence and reproduction

The original extraction and linkage evidence is retained with its recorded
hashes. The current sources separate the generic probability arguments from
the native instantiation. A [cloud replay](source/blueprint/verification/current-source-replay.json)
checks both Lean libraries, matches all 22 concrete and 16 generic axiom closures,
and preserves four regressions. It does not repeat Rust extraction or native execution.
The [parameterized audit](source/scripts/check-parameterized-axioms.lean)
separately checks fourteen new endpoints against the standard-axiom allowlist.

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
