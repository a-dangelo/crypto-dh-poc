import Concrete.Primitives
import Concrete.Wire
import DhPoc.RawSecurity

namespace DhConcrete
open curve25519 Aeneas Aeneas.Std Result Aeneas.Std.WP

abbrev Secret := Array U8 64#usize
abbrev Public := Array U8 32#usize
abbrev Key := Option Public

def decodeScalar (raw : Secret) : Scalar := (raw.asNat 8 % L : ℕ)
noncomputable def key (g : Group) : Key := some (point g)

/-- Helper composition model; Native.lean checks linkage to the actual extracted Rust session. -/
noncomputable def operations : dh_core.Dh Unit Secret Public Key where
  «public» := publicCompose
  agree := agreeCompose

theorem public_eq (raw : Secret) :
    publicCompose raw = .ok (point (decodeScalar raw • generator)) := by
  apply result_eq_of_spec
  apply spec_mono (publicCompose_spec raw)
  intro bytes hb
  apply bytes_asNat_injective
  simp only [point_asNat]
  change bytes.asNat 8 = Ristretto.encodeRep ((decodeScalar raw • generator).val)
  rw [decodeScalar, coe_scalar_mul]
  exact hb

theorem agree_eq (raw : Secret) (g : Group) :
    agreeCompose raw (point g) = .ok (key (decodeScalar raw • g)) := by
  apply result_eq_of_spec
  apply spec_mono (agreeCompose_spec raw (point g) g (point_asNat g))
  rintro result ⟨bytes, rfl, hb⟩
  apply congrArg some
  apply bytes_asNat_injective
  simp only [point_asNat]
  change bytes.asNat 8 = Ristretto.encodeRep ((decodeScalar raw • g).val)
  rw [decodeScalar, coe_scalar_mul]
  exact hb

noncomputable def model : DhPoc.RawPrimitiveModel Unit Secret Public Key Scalar Group where
  operations := operations
  scalar := decodeScalar
  point := point
  key := key
  generator := generator
  public_spec := public_eq
  agree_spec := agree_eq

#print axioms model
#print axioms public_eq
#print axioms agree_eq
end DhConcrete
