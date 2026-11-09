import DhPoc.Parameterized
import VCVio.CryptoFoundations.Asymptotics.ComputationalComplexity
import VCVio.OracleComp.Constructions.SampleableType.Measure

/-!
# A backend-relative strict-PPT security bridge

Adversaries are one coin-only program on a security-parameter-tagged input,
not an unrelated program chosen at each parameter. The existing VCVio
`IsPPTBy` predicate certifies their entire interaction tree. Its backend and
input representations remain explicit; conventional machine-model PPT and
the cost of native curve code are not asserted here. A conventional
cryptographic instantiation must certify a unary security-parameter encoding
and the polynomial growth of all other represented inputs. The sampling-width
condition used below proves statistical negligibility, not sampler runtime.

The DDH reduction only encodes its input and invokes the session adversary.
Its strict-PPT proof below is derived from executable polynomial encoding
code and the backend's polynomial composition law, rather than an abstract
efficiency-preservation assumption. Probability semantics are VCVio's
existing fair-coin interpretation and `ProbComp` game semantics.
-/

namespace DhPoc.PPT

open OracleComp OracleSpec PFunctor
open PFunctor.DynSystem.DynComputation
open OracleComp.Complexity

section PolynomialPrecomposition

variable {C : StepClass} [C.HasProd] [C.HasSum] [C.HasOption]
    {Q : QuantitativeStepClass C} [Q.HasComposition]
    {p : PFunctor} [DecidableEq p.A] {input output source : Type}
    {bd : Boundary C p input output} {sourceRep : C.Str source}
    {label : Type} {contract : OracleContract Q bd.interface label}
    {program : input → FreeM p output} {encode : source → input}

/-- Polynomial input precomposition, including the executable composition
overhead, leaves the adversary's oracle transcript unchanged. -/
def precompWitness
    (composition : Q.PolynomialComposition)
    (encoding : Q.PolyRealizer sourceRep bd.input encode)
    (witness : StrictPPTWitness Q bd contract program) :
    StrictPPTWitness Q (bd.withInput sourceRep) contract (program ∘ encode) := by
  let overhead : _root_.Complexity.FirstOrderPolynomial :=
    .add encoding.work
      (composition.composeOverhead encoding.code witness.realization.initCode)
  let extra : ExecutionCostPolynomial (ResponseModulus label) :=
    { work := ExecutionCostPolynomial.ofFirstOrder overhead
      queries := .const 0
      traffic := .const 0
      peakStateSize := .const 0
      peakHeadSize := .const 0 }
  let continuation := witness.runBound.polynomial.comp
    (ExecutionCostPolynomial.ofFirstOrder encoding.outputSize)
  refine
    { realization := witness.realization.precomp encoding.code
      implements := ?_
      outputRecovery :=
        { polynomial := witness.outputRecovery.polynomial
          output_le := witness.outputRecovery.output_le }
      runBound :=
        { polynomial := extra + continuation
          runsWithin := ?_ } }
  · change (witness.realization.machine.setInit
      (witness.realization.machine.init ∘ encode)).Implements (program ∘ encode)
    rw [← witness.realization.machine.contramapInput_eq_setInit encode]
    exact witness.implements.contramapInput encode
  · intro model
    apply ((witness.runBound.runsWithin model).precomp encoding.code).mono
    intro value
    have hwork : ExecutionCost.ofWork
        (Q.cost encoding.code value +
          Q.composeOverhead encoding.code witness.realization.initCode value) ≤
        extra.eval model.modulus (Q.size sourceRep value) := by
      refine ⟨?_, le_rfl, le_rfl, le_rfl, le_rfl⟩
      change _ ≤ (ExecutionCostPolynomial.ofFirstOrder overhead).eval model.modulus
        (Q.size sourceRep value)
      rw [ExecutionCostPolynomial.eval_ofFirstOrder]
      exact Nat.add_le_add (encoding.work_le value)
        (composition.composeOverhead_le encoding.code witness.realization.initCode value)
    have hcontinuation : witness.runBound.polynomial.eval model.modulus
        (Q.size bd.input (encode value)) ≤
        continuation.eval model.modulus (Q.size sourceRep value) := by
      simp only [continuation, ExecutionCostPolynomial.eval_comp,
        ExecutionCostPolynomial.eval_ofFirstOrder]
      exact witness.runBound.polynomial.eval_mono_input model.modulus_monotone
        (encoding.outputSize_le value)
    exact (ExecutionCost.add_le_add hwork hcontinuation).trans
      (ExecutionCostPolynomial.add_eval_le_eval_add extra continuation model.modulus
        (Q.size sourceRep value))

/-- VCVio strict PPT is preserved by certified polynomial input encoding. -/
theorem isPPTBy_precomp
    {input output source : Type}
    {bd : Boundary C coinSpec.toPFunctor input output}
    {sourceRep : C.Str source} {encode : source → input}
    (composition : Q.PolynomialComposition)
    (encoding : Q.PolyRealizer sourceRep bd.input encode)
    {program : input → OracleComp coinSpec output}
    (hppt : IsPPTBy Q bd program) :
    IsPPTBy Q (bd.withInput sourceRep) (program ∘ encode) := by
  obtain ⟨witness⟩ := hppt
  exact ⟨precompWitness composition encoding witness⟩

end PolynomialPrecomposition

/-! ## Coin programs and their existing probability interpretation -/

/-- One input carries the security parameter and the three session values. -/
abbrev SessionInput (P K : ℕ → Type) := (n : ℕ) × (P n × P n × K n)

/-- DDH supplies the generator, two public values, and the challenge. -/
abbrev DDHInput (G : ℕ → Type) := (n : ℕ) × (G n × G n × G n × G n)

abbrev SessionAdversary (P K : ℕ → Type) :=
  SessionInput P K → OracleComp coinSpec Bool

abbrev DDHAdversary (G : ℕ → Type) :=
  DDHInput G → OracleComp coinSpec Bool

/-- Use VCVio's existing uniform Boolean handler, rather than defining a new
probability distribution or treating arbitrary samplers as efficient. -/
def interpretCoins {α : Type} (program : OracleComp coinSpec α) : ProbComp α :=
  simulateQ uniformSampleImpl program

/-- Interpreting the coin syntax preserves its VCVio output distribution. -/
theorem interpretCoins_evalDistEq {α : Type} (program : OracleComp coinSpec α) :
    interpretCoins program =ᵈ program :=
  uniformSampleImpl.evalDistEq_simulateQ program

def sessionFamily {P K : ℕ → Type} (A : SessionAdversary P K) : FamilyAdversary P K :=
  fun n pa pb key => interpretCoins (A ⟨n, pa, pb, key⟩)

def ddhFamily {G : ℕ → Type} {q : ℕ → ℕ}
    (A : DDHAdversary G) (n : ℕ) : DiffieHellman.DDHAdversary (ZMod (q n)) (G n) :=
  fun g pa pb challenge => interpretCoins (A ⟨n, g, pa, pb, challenge⟩)

section Security

variable {D P K G : ℕ → Type} {q w : ℕ → ℕ}
    [∀ n, Fact (Nat.Prime (q n))] [∀ n, AddCommGroup (G n)]
    [∀ n, Module (ZMod (q n)) (G n)]

/-- The reduction's complete deterministic preprocessing, including retaining
the security parameter. The supplied generator is unused, as in `rawReduction`. -/
def encodeInput
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n)) :
    DDHInput G → SessionInput P K :=
  fun ⟨n, _, pa, pb, challenge⟩ =>
    ⟨n, (M n).point pa, (M n).point pb, (M n).key challenge⟩

def reduce
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (A : SessionAdversary P K) : DDHAdversary G :=
  A ∘ encodeInput M

/-- The syntactic reduction is exactly the reduction used by the checked
probabilistic security theorem after interpreting the coin queries. -/
theorem ddhFamily_reduce
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (A : SessionAdversary P K) :
    ddhFamily (q := q) (reduce M A) = familyReduction M (sessionFamily A) :=
  rfl

noncomputable def sessionGame
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n)) :
    SecurityGame (SessionAdversary P K) :=
  ⟨fun A => parameterizedSessionAdvantage M (sessionFamily A)⟩

noncomputable def ddhGame
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n)) :
    SecurityGame (DDHAdversary G) :=
  ⟨fun A n => DiffieHellman.ddhAdvantage (M n).generator (ddhFamily (q := q) A n)⟩

/-- Session security against the actual VCVio backend-relative strict-PPT
class. The encoding and backend composition certificates replace an abstract
reduction-closure premise. Neither native runtime nor backend adequacy is
inferred from the algebraic primitive model. -/
theorem session_secure_isPPTBy
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    (b : ℕ → ℕ) (hq : ∀ n, q n ≤ 2 ^ b n) (hw : ∀ n, b n + n + 2 ≤ w n)
    {C : StepClass} [C.HasProd] [C.HasSum] [C.HasOption]
    (Q : QuantitativeStepClass C) [Q.HasComposition]
    (bd : Boundary C coinSpec.toPFunctor (SessionInput P K) Bool)
    (ddhInputRep : C.Str (DDHInput G))
    (composition : Q.PolynomialComposition)
    (encoding : Q.PolyRealizer ddhInputRep bd.input (encodeInput M))
    (hDDH : (ddhGame M).secureAgainst (IsPPTBy Q (bd.withInput ddhInputRep))) :
    (sessionGame M).secureAgainst (IsPPTBy Q bd) := by
  intro A hA
  apply parameterizedSessionAdvantage_negligible M (sessionFamily A) b hq hw
  have hreduce : IsPPTBy Q (bd.withInput ddhInputRep) (reduce M A) :=
    isPPTBy_precomp composition encoding hA
  exact hDDH (reduce M A) hreduce

end Security
end DhPoc.PPT
