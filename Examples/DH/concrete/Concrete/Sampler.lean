import Concrete.Model

/-! An ideal uniform 512-bit input distribution and its scalar reduction.
The decoded scalar distribution is not assumed to be uniform. -/

namespace DhConcrete
open Aeneas Aeneas.Std OracleComp OracleSpec

abbrev RandomTape := Fin (256 ^ 64)

/-- The fixed-width little-endian representation of a 512-bit input value. -/
def rawOfNat (n : RandomTape) : Secret :=
  Array.from ((Nat.digitsAppend 256 64 n.val).pmap
    (fun d hd => U8.ofNatCore d hd)
    (fun d hd => Nat.lt_of_mem_digitsAppend (by decide) 64 d hd))
    (by simpa using Nat.length_digitsAppend (by decide : 1 < 256) 64 n.isLt)

theorem rawOfNat_asNat (n : RandomTape) : (rawOfNat n).asNat 8 = n.val := by
  simp only [Array.asNat, rawOfNat, Array.from_val, List.map_pmap]
  simp only [U8.ofNatCore_val_eq]
  simp [Nat.digitsAppend, Nat.ofDigits_append_replicate_zero, Nat.ofDigits_digits]

/-- The scalar decoder reduces the represented integer modulo the group order. -/
theorem decode_rawOfNat (n : RandomTape) :
    decodeScalar (rawOfNat n) = ((n.val % curve25519.L : ℕ) : Scalar) := by
  simp only [decodeScalar, rawOfNat_asNat]

/-- The ideal distribution of a caller-supplied uniform 64-byte input. -/
def uniformWide : ProbComp Secret := rawOfNat <$> ($ᵗ RandomTape)

/-- Decoding `uniformWide` gives the distribution obtained by modular reduction
of a uniformly sampled 512-bit integer. -/
theorem uniformWide_decode :
    decodeScalar <$> uniformWide =
      (fun n : RandomTape => ((n.val % curve25519.L : ℕ) : Scalar)) <$> ($ᵗ RandomTape) := by
  simp only [uniformWide, Functor.map_map]
  congr 1
  funext n
  exact decode_rawOfNat n

end DhConcrete
