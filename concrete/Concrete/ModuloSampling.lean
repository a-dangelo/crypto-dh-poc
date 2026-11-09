import Concrete.Sampler
import DhPoc.ModuloSampling

namespace DhConcrete
open OracleComp OracleSpec MeasureTheory ProbabilityTheory
open scoped ENNReal

/-- Compatibility name for the generic modular-reduction theorem. -/
theorem uniform_modulo_measureETVDist_le (n m : ℕ) [NeZero n] [NeZero m] :
    letI : MeasurableSpace (ZMod m) := ⊤
    measureETVDist ((fun x : Fin n => (x.val : ZMod m)) <$> ($ᵗ Fin n))
      ($ᵗ ZMod m) ≤ (n % m : ℕ) / (n : ℝ≥0∞) :=
  DhPoc.uniform_modulo_measureETVDist_le n m

/-- The decoded uniform 64-byte sampler satisfies the modular-reduction bias bound. -/
theorem uniformWide_scalar_measureETVDist_le :
    letI : MeasurableSpace Scalar := ⊤
    measureETVDist (decodeScalar <$> uniformWide) ($ᵗ Scalar) ≤
      (256 ^ 64 % curve25519.L : ℕ) / ((256 ^ 64 : ℕ) : ℝ≥0∞) := by
  let : MeasurableSpace Scalar := ⊤
  rw [uniformWide_decode]
  simpa only [ZMod.natCast_mod] using
    uniform_modulo_measureETVDist_le (256 ^ 64) curve25519.L

#print axioms uniform_modulo_measureETVDist_le
#print axioms uniformWide_scalar_measureETVDist_le

end DhConcrete
