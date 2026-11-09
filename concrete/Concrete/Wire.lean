import Concrete.Algebra
import Concrete.Bytes

namespace DhConcrete
open curve25519 Aeneas Aeneas.Std Result Aeneas.Std.WP

noncomputable def point (g : Group) : Array U8 32#usize :=
  bytesOfNat (encode g) (lt_trans (Ristretto.encodeRep_lt _) (by
    exact lt_trans p_lt_two_pow_255 (by norm_num)))

@[simp] theorem point_asNat (g : Group) : (point g).asNat 8 = encode g :=
  bytesOfNat_asNat _ _

theorem result_eq_of_spec {α : Type} (m : Result α) (x : α)
    (h : m ⦃ r => r = x ⦄) : m = .ok x := by
  cases m <;> simp_all

end DhConcrete
