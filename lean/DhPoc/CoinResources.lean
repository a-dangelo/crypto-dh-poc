import DhPoc.CoinSecurity

/-!
# Polynomial randomness bounds in the security parameter

VCVio's fair-coin response envelope is constant. Substituting that envelope into
its existing second-order polynomial certificate gives an ordinary polynomial.
An explicit polynomial input-size envelope then turns it into a bound in the
security parameter. Together with a polynomial sampling width, this bounds all
coin queries in both complete experiments. This is not a proof of canonical
unary encoding, backend adequacy, or running time for honest group operations.
-/

namespace DhPoc.CoinResources

open OracleComp OracleSpec PFunctor
open PFunctor.DynSystem.DynComputation
open OracleComp.Complexity

variable {C : StepClass} [C.HasProd] [C.HasSum] [C.HasOption]
    {Q : QuantitativeStepClass C} {input output : Type}
    {bd : Boundary C coinSpec.toPFunctor input output}
    {program : input → OracleComp coinSpec output}

/-- Specialize the existing second-order query certificate to the constant
fair-coin answer-size envelope. -/
def queryPolynomial
    (witness : StrictPPTWitness Q bd (fairCoinContract Q bd.interface) program) :
    _root_.Complexity.FirstOrderPolynomial :=
  witness.polynomial.queries.subst fun _ => .const
    (max (Q.size bd.idx ⟨PUnit.unit, false⟩) (Q.size bd.idx ⟨PUnit.unit, true⟩))

theorem queryPolynomial_eval
    (witness : StrictPPTWitness Q bd (fairCoinContract Q bd.interface) program) (s : ℕ) :
    (queryPolynomial witness).eval s =
      (witness.polynomial.eval (fairCoinModel Q bd.interface).modulus s).queries := by
  unfold queryPolynomial _root_.Complexity.FirstOrderPolynomial.eval
  rw [_root_.Complexity.SecondOrderPolynomial.eval_subst]
  change witness.polynomial.queries.eval _ s = witness.polynomial.queries.eval _ s
  congr 1

/-- One polynomial bounds every coin branch of the one input-uniform program. -/
theorem isPPTBy_coinBound (hppt : IsPPTBy Q bd program) :
    ∃ p : _root_.Complexity.FirstOrderPolynomial, ∀ value,
      (program value).IsTotalRollBound (p.eval (Q.size bd.input value)) := by
  obtain ⟨witness⟩ := hppt
  refine ⟨queryPolynomial witness, fun value => ?_⟩
  rw [queryPolynomial_eval]
  exact witness.isTotalRollBound (fairCoinModel Q bd.interface) (fun _ _ => trivial) value

/-- A polynomial input-size envelope yields one polynomial query bound in `n`.
The envelope is an explicit premise, not inferred from an arbitrary representation. -/
theorem isPPTBy_parameterBound {I : ℕ → Type}
    {bd : Boundary C coinSpec.toPFunctor ((n : ℕ) × I n) output}
    {program : ((n : ℕ) × I n) → OracleComp coinSpec output}
    (hppt : IsPPTBy Q bd program)
    (inputBound : _root_.Complexity.FirstOrderPolynomial)
    (hinput : ∀ n x, Q.size bd.input ⟨n, x⟩ ≤ inputBound.eval n) :
    ∃ p : _root_.Complexity.FirstOrderPolynomial, ∀ n x,
      (program ⟨n, x⟩).IsTotalRollBound (p.eval n) := by
  obtain ⟨p, hp⟩ := isPPTBy_coinBound hppt
  refine ⟨p.comp inputBound, fun n x => ?_⟩
  rw [_root_.Complexity.FirstOrderPolynomial.eval_comp]
  exact (hp ⟨n, x⟩).mono (p.eval_monotone (hinput n x))

/-- Polynomial raw-sampling width plus the actual strict-PPT adversary witness
bounds every coin branch in both complete experiments by one polynomial in `n`.
Only coin queries are counted for the complete games; deterministic work is not. -/
theorem games_polynomial_coinBound
    {D P K G : ℕ → Type} {q w : ℕ → ℕ}
    [∀ n, Fact (Nat.Prime (q n))] [∀ n, AddCommGroup (G n)]
    [∀ n, Module (ZMod (q n)) (G n)]
    (M : (n : ℕ) → PrimeOrderModel (D n) (P n) (K n) (G n) (q n) (w n))
    {bd : Boundary C coinSpec.toPFunctor (PPT.SessionInput P K) Bool}
    (A : PPT.SessionAdversary P K) (hppt : IsPPTBy Q bd A)
    (inputBound widthBound : _root_.Complexity.FirstOrderPolynomial)
    (hinput : ∀ n pa pb k, Q.size bd.input ⟨n, pa, pb, k⟩ ≤ inputBound.eval n)
    (hwidth : ∀ n, w n ≤ widthBound.eval n) :
    ∃ p : _root_.Complexity.FirstOrderPolynomial, ∀ n,
      (CoinSecurity.real (M n) (fun pa pb k => A ⟨n, pa, pb, k⟩)).IsTotalRollBound (p.eval n) ∧
      (CoinSecurity.ideal (M n) (fun pa pb k => A ⟨n, pa, pb, k⟩)).IsTotalRollBound (p.eval n) := by
  obtain ⟨r, hr⟩ := isPPTBy_parameterBound hppt inputBound
    (fun n ⟨pa, pb, k⟩ => hinput n pa pb k)
  refine ⟨.add (.mul (.const 3) widthBound) r, fun n => ?_⟩
  have hreal := CoinSecurity.real_rollBound (M n) (fun pa pb k => A ⟨n, pa, pb, k⟩)
    (r.eval n) (fun pa pb k => hr n ⟨pa, pb, k⟩)
  have hideal := CoinSecurity.ideal_rollBound (M n) (fun pa pb k => A ⟨n, pa, pb, k⟩)
    (r.eval n) (fun pa pb k => hr n ⟨pa, pb, k⟩)
  simp only [_root_.Complexity.FirstOrderPolynomial.eval_add,
    _root_.Complexity.FirstOrderPolynomial.eval_mul, _root_.Complexity.FirstOrderPolynomial.eval_const]
  exact ⟨hreal.mono (by have := hwidth n; omega),
    hideal.mono (Nat.add_le_add_right (Nat.mul_le_mul_left 3 (hwidth n)) _)⟩

end DhPoc.CoinResources
