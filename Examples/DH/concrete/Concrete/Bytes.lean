import Aeneas.Std.Scalar.Notations
import Defs.Array
import Mathlib.Data.Nat.Digits.Lemmas

open Aeneas Aeneas.Std
namespace DhConcrete

/-- The canonical 32-byte little-endian representation of a bounded integer. -/
def bytesOfNat (n : ℕ) (hn : n < 256 ^ 32) : Array U8 32#usize :=
  Array.from ((Nat.digitsAppend 256 32 n).pmap
    (fun d hd => U8.ofNatCore d hd)
    (fun d hd => Nat.lt_of_mem_digitsAppend (by decide) 32 d hd))
    (by simpa using Nat.length_digitsAppend (by decide : 1 < 256) 32 hn)

theorem bytesOfNat_asNat (n : ℕ) (hn : n < 256 ^ 32) :
    (bytesOfNat n hn).asNat 8 = n := by
  simp only [Array.asNat, bytesOfNat, Array.from_val, List.map_pmap]
  simp only [U8.ofNatCore_val_eq]
  simp [Nat.digitsAppend, Nat.ofDigits_append_replicate_zero, Nat.ofDigits_digits]

theorem bytes_asNat_injective : Function.Injective
    (fun a : Array U8 32#usize => a.asNat 8) := by
  intro a b h
  apply Aeneas.Std.Array.ext
  have hm : a.val.map UScalar.val = b.val.map UScalar.val := by
    apply Nat.ofDigits_inj_of_len_eq (by decide : 1 < 256)
    · simp
    · intro d hd
      obtain ⟨x, _, rfl⟩ := List.mem_map.mp hd
      exact x.bv.isLt
    · intro d hd
      obtain ⟨x, _, rfl⟩ := List.mem_map.mp hd
      exact x.bv.isLt
    · exact h
  exact Function.Injective.list_map (fun _ _ h => UScalar.eq_of_val_eq h) hm

end DhConcrete

#print axioms DhConcrete.bytesOfNat_asNat
#print axioms DhConcrete.bytes_asNat_injective
