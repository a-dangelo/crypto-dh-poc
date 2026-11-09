import VCVio.CryptoFoundations.Asymptotics.Negligible
import Mathlib.Analysis.SpecificLimits.Normed
import Mathlib.Tactic

/-!
# Sampling width schedules

The remainder bound is a statistical upper bound, not the exact total variation
distance. A linear surplus of random input bits makes four such errors
negligible. This arithmetic result does not assert group-family DDH hardness.
-/

namespace DhPoc
open ENNReal Asymptotics Filter

/-- Upper bound for reduction of a uniform `w`-bit integer modulo `q`. -/
noncomputable def samplingError (q w : ℕ) : ℝ≥0∞ :=
  ((2 ^ w % q : ℕ) : ℝ≥0∞) / (2 : ℝ≥0∞) ^ w

/-- If the order fits in `b` bits and the sampler has `n+2` additional bits,
the four-replacement error is at most `2⁻ⁿ`. -/
theorem four_samplingError_le_exp (q w b n : ℕ) [NeZero q]
    (hq : q ≤ 2 ^ b) (hw : b + n + 2 ≤ w) :
    4 * samplingError q w ≤ ((2 : ℝ≥0∞) ^ n)⁻¹ := by
  have hr : 2 ^ w % q ≤ 2 ^ b :=
    (Nat.mod_lt _ (Nat.pos_of_ne_zero (NeZero.ne q))).le.trans hq
  have hnat : 4 * (2 ^ w % q) * 2 ^ n ≤ 2 ^ w := by
    calc
      4 * (2 ^ w % q) * 2 ^ n ≤ 4 * 2 ^ b * 2 ^ n :=
        Nat.mul_le_mul_right (2 ^ n) (Nat.mul_le_mul_left 4 hr)
      _ = 2 ^ (b + n + 2) := by rw [pow_add, pow_add]; ring
      _ ≤ 2 ^ w := pow_le_pow_right' (by norm_num) hw
  have hreal : (4 : ℝ) * (2 ^ w % q : ℕ) * 2 ^ n ≤ 2 ^ w := by
    exact_mod_cast hnat
  apply (ENNReal.toReal_le_toReal
    (ENNReal.mul_ne_top (by simp)
      (ENNReal.div_ne_top (by simp) (by simp))) (by simp)).mp
  simp only [ENNReal.toReal_mul, ENNReal.toReal_div,
    ENNReal.toReal_pow, ENNReal.toReal_natCast, ENNReal.toReal_ofNat,
    ENNReal.toReal_inv]
  rw [← mul_div_assoc, inv_eq_one_div, div_le_div_iff₀ (by positivity) (by positivity)]
  simpa using hreal

/-- The inverse powers of two are negligible in VCVio's standard sense. -/
theorem negligible_two_inv_pow :
    negligible (fun n : ℕ => ((2 : ℝ≥0∞) ^ n)⁻¹) := by
  rw [negligible_iff_superpolynomialDecay_toReal
    (f := fun n : ℕ => ((2 : ℝ≥0∞) ^ n)⁻¹) (fun _ => by simp)]
  intro k
  simp only [ENNReal.toReal_inv, ENNReal.toReal_pow, ENNReal.toReal_ofNat]
  simpa only [one_div, inv_pow] using
    (tendsto_pow_const_mul_const_pow_of_lt_one k
      (show 0 ≤ (1 / 2 : ℝ) by norm_num) (show (1 / 2 : ℝ) < 1 by norm_num))

/-- The sampling loss is negligible for every nonzero order family satisfying
the stated width schedule. This does not itself require, or imply, DDH hardness. -/
theorem four_samplingError_negligible (q w b : ℕ → ℕ) [∀ n, NeZero (q n)]
    (hq : ∀ n, q n ≤ 2 ^ b n) (hw : ∀ n, b n + n + 2 ≤ w n) :
    negligible (fun n => 4 * samplingError (q n) (w n)) :=
  negligible_of_le (fun n => four_samplingError_le_exp (q n) (w n) (b n) n (hq n) (hw n))
    negligible_two_inv_pow

end DhPoc
