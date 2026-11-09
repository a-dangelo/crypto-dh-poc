import Concrete.Sampler
import Mathlib.Basic.ENNReal.Real
import Mathlib.Tactic.NormNum

namespace DhConcrete
open scoped ENNReal

/-- A rigorous upper bound used below, not the exact total variation distance. -/
noncomputable def wideSamplingError : ℝ≥0∞ :=
  ((256 ^ 64 % curve25519.L : ℕ) : ℝ≥0∞) / ((256 ^ 64 : ℕ) : ℝ≥0∞)

/-- Four replacements still give an additive loss smaller than 2^-260. -/
theorem four_wideSamplingError_lt :
    4 * wideSamplingError < ((2 : ℝ≥0∞) ^ (260 : ℕ))⁻¹ := by
  apply (ENNReal.toReal_lt_toReal
    (ENNReal.mul_ne_top (by simp) (ENNReal.div_ne_top (by simp) (by norm_num)))
    (by simp)).mp
  norm_num [wideSamplingError, curve25519.L, ENNReal.toReal_mul,
    ENNReal.toReal_div, ENNReal.toReal_inv, ENNReal.toReal_pow]
  norm_num [pow_succ]

end DhConcrete
