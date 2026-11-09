import Concrete.Wide
import Concrete.ModuloSampling
import Concrete.SamplingHybrids
import Concrete.SamplingError

namespace DhConcrete
open Aeneas.Std OracleComp OracleSpec ENNReal

/-- Standard uniform-scalar DDH controls the extracted Rust game, up to the
proved bias of its two independent wide-reduced secret scalars in each branch. -/
theorem wideAdvantage_le_standard
    (hTarget : target = "x86_64-no-tables")
    (adversary : Public → Public → Key → ProbComp Bool) :
    nativeAdvantage uniformWide uniformWide adversary ≤
      DiffieHellman.ddhAdvantage generator (DhPoc.rawReduction model adversary) +
        4 * wideSamplingError := by
  rw [wideAdvantage_eq hTarget]
  refine (DhPoc.sampledDDHAdvantage_le_standard decodeScalar generator
    uniformWide uniformWide (DhPoc.rawReduction model adversary)).trans ?_
  have h : (letI : MeasurableSpace Scalar := ⊤
      measureETVDist (decodeScalar <$> uniformWide) ($ᵗ Scalar)) ≤ wideSamplingError := by
    simpa only [wideSamplingError, Nat.cast_pow, Nat.cast_ofNat] using
      uniformWide_scalar_measureETVDist_le
  have hsum := mul_le_mul (show (2 : ℝ≥0∞) ≤ 2 from le_rfl) (add_le_add h h) bot_le bot_le
  have heq : 2 * (wideSamplingError + wideSamplingError) = 4 * wideSamplingError := by ring
  rw [heq] at hsum
  exact add_le_add le_rfl hsum

/-- The standard-DDH corollary uses an explicit supplied hardness bound, plus
an additive statistical error strictly below 2^-260. -/
theorem wideAdvantage_le_of_standardDDH
    (hTarget : target = "x86_64-no-tables")
    (adversary : Public → Public → Key → ProbComp Bool) (ε : ℝ≥0∞)
    (hDDH : DiffieHellman.ddhAdvantage generator (DhPoc.rawReduction model adversary) ≤ ε) :
    nativeAdvantage uniformWide uniformWide adversary ≤ ε + ((2 : ℝ≥0∞) ^ (260 : ℕ))⁻¹ :=
  (wideAdvantage_le_standard hTarget adversary).trans
    (add_le_add hDDH four_wideSamplingError_lt.le)

end DhConcrete
