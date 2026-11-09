import DhPoc.PPT
import Mathlib.Logic.Equiv.Fin.Basic

/-!
# Fixed-width sampling from explicit fair coins

The sampler below makes one Boolean query per bit. Its exact output law is the
uniform distribution on `Fin (2^w)`, so it can replace the ideal raw-input sampler
in the existing security theorem without a statistical loss. The pathwise bound
counts coin queries, not arithmetic work, bit generation, or native runtime.
-/

namespace DhPoc.CoinSampling

open OracleComp OracleSpec PFunctor MeasureTheory ProbabilityTheory

/-- Add one high bit to an unsigned `w`-bit value. -/
def prependBit (w : ℕ) : Bool × Fin (2 ^ w) ≃ Fin (2 ^ (w + 1)) :=
  ((Equiv.prodCongr finTwoEquiv.symm (Equiv.refl _)).trans finProdFinEquiv).trans
    (finCongr (by rw [pow_succ, Nat.mul_comm]))

/-- A finite coin-only program, with no rejection loop or arbitrary-range query. -/
def sample : (w : ℕ) → OracleComp coinSpec (Fin (2 ^ w))
  | 0 => pure 0
  | w + 1 => (fun bit rest => prependBit w (bit, rest)) <$> coin <*> sample w

/-- Every branch consumes at most `w` coin queries, including width zero. -/
theorem sample_rollBound (w : ℕ) : (sample w).IsTotalRollBound w := by
  induction w with
  | zero => exact FreeM.isTotalRollBound_pure _ _
  | succ w ih =>
      have hcoin : coin.IsTotalRollBound 1 := ⟨by decide, fun _ => trivial⟩
      have hmap : ((fun bit rest => prependBit w (bit, rest)) <$> coin).IsTotalRollBound 1 :=
        (FreeM.isRollBound_map_iff _ _ _ _ _).mpr hcoin
      simpa only [sample, Nat.add_comm 1 w] using FreeM.isTotalRollBound_seq hmap ih

/-- Independent fair bits produce exactly a uniform fixed-width integer. -/
theorem sample_evalDist (w : ℕ) :
    𝒟[sample w] = uniformOn Set.univ := by
  induction w with
  | zero =>
      change 𝒟[(pure (0 : Fin 1) : OracleComp coinSpec (Fin 1))] = _
      apply Measure.ext_of_singleton
      intro x
      have hx : x = 0 := Subsingleton.elim _ _
      simp [hx, evalDist_pure, uniformOn_univ_apply_singleton]
  | succ w ih =>
      exact evalDist_seq_map_eq_uniformOn coin (sample w)
        (fun bit rest => prependBit w (bit, rest))
        (OracleComp.evalDist_liftM_query_uniform (spec := coinSpec) ()) ih
        Measurable.of_discrete (prependBit w).bijective

/-- The coin program has exactly the canonical raw-sample law. -/
theorem sample_evalDistEq (w : ℕ) :
    sample w =ᵈ ($ᵗ Fin (2 ^ w)) := by
  apply EvalDistEq.of_evalDist_eq
  rw [sample_evalDist, SampleableType.evalDist_uniformSample]

/-- VCVio's fair-coin interpretation preserves that exact raw-sample law. -/
theorem interpret_sample_evalDistEq (w : ℕ) :
    PPT.interpretCoins (sample w) =ᵈ ($ᵗ Fin (2 ^ w)) :=
  (PPT.interpretCoins_evalDistEq _).trans (sample_evalDistEq w)

/-- A polynomially bounded width schedule gives a polynomial coin-query bound.
This theorem deliberately does not promote query count to running time. -/
theorem sample_polynomial_rollBound (w : ℕ → ℕ)
    (widthBound : _root_.Complexity.FirstOrderPolynomial)
    (hw : ∀ n, w n ≤ widthBound.eval n) (n : ℕ) :
    (sample (w n)).IsTotalRollBound (widthBound.eval n) :=
  FreeM.IsTotalRollBound.mono (sample_rollBound _) (hw n)

end DhPoc.CoinSampling
