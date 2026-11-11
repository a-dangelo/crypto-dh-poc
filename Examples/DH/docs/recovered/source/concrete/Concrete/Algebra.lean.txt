import Curve25519.Ristretto.Encoding
import Curve25519.Ristretto.Even
import Mathlib.Algebra.Module.Torsion.Basic

namespace DhConcrete
open curve25519

abbrev Scalar := ZMod L
noncomputable abbrev Group := AddSubgroup.torsionBy edwards.Point (L : ℤ)
noncomputable instance : Module Scalar Group := AddSubgroup.torsionBy.zmodModule

noncomputable def generator : Group :=
  ⟨basepoint, AddSubgroup.torsionBy.nsmul_iff.mpr L_nsmul_basepoint⟩

theorem even_point (g : Group) : Even g.val := by
  apply (even_iff_four_mul_L_nsmul _).mpr
  rw [mul_smul, AddSubgroup.torsionBy.nsmul_iff.mp g.property, smul_zero]

theorem coe_scalar_mul (n : ℕ) (g : Group) :
    ((n : Scalar) • g).val = n • g.val := by
  rw [Nat.cast_smul_eq_nsmul]
  rfl

/-- The canonical integer represents the efficient RFC 9496 wire encoding. -/
noncomputable def encode (g : Group) : ℕ := Ristretto.encodeRep g.val

/-- Decoding need not return the same Edwards point, only a Ristretto-equivalent one. -/
theorem decode_encode (g : Group) :
    ∃ q, Ristretto.decodeRep (encode g) = some q ∧ edwards.Rel g.val q :=
  Ristretto.decodeRep_encodeRep (even_point g)

/-- Multiplication of a decoded representative preserves the encoded shared secret. -/
theorem agree_decode (g : Group) (n : ℕ) (q : edwards.Point)
    (hq : Ristretto.decodeRep (encode g) = some q) :
    Ristretto.encodeRep (n • q) = Ristretto.encodeRep (n • g.val) := by
  obtain ⟨r, hr, hrel⟩ := decode_encode g
  have heq : r = q := Option.some.inj (hr.symm.trans hq)
  subst r
  exact (Ristretto.encodeRep_rel ((even_point g).nsmul_right n)
    (TwistedEdwardsModel.rel_nsmul n hrel)).symm

theorem shared_secret_comm (a b : Scalar) :
    encode (a • (b • generator)) = encode (b • (a • generator)) := by
  rw [smul_smul, smul_smul, mul_comm]

#print axioms agree_decode
#print axioms shared_secret_comm
end DhConcrete
