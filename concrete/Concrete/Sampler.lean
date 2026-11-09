import Concrete.Model

/-! An explicit ideal 512-bit random tape. Its scalar reduction is not assumed uniform. -/

namespace DhConcrete
open Aeneas Aeneas.Std OracleComp OracleSpec

abbrev RandomTape := Fin (256 ^ 64)

/-- Fixed-width little-endian representation of one uniformly selected 512-bit integer. -/
def rawOfNat (n : RandomTape) : Secret :=
  Array.from ((Nat.digitsAppend 256 64 n.val).pmap
    (fun d hd => U8.ofNatCore d hd)
    (fun d hd => Nat.lt_of_mem_digitsAppend (by decide) 64 d hd))
    (by simpa using Nat.length_digitsAppend (by decide : 1 < 256) 64 n.isLt)

theorem rawOfNat_asNat (n : RandomTape) : (rawOfNat n).asNat 8 = n.val := by
  simp only [Array.asNat, rawOfNat, Array.from_val, List.map_pmap]
  simp only [U8.ofNatCore_val_eq]
  simp [Nat.digitsAppend, Nat.ofDigits_append_replicate_zero, Nat.ofDigits_digits]

/-- The actual wide reduction, with no ideal-uniform scalar substitution. -/
theorem decode_rawOfNat (n : RandomTape) :
    decodeScalar (rawOfNat n) = ((n.val % curve25519.L : ℕ) : Scalar) := by
  simp only [decodeScalar, rawOfNat_asNat]

/-- The probabilistic model of ideal caller-supplied 64-byte entropy. -/
def uniformWide : ProbComp Secret := rawOfNat <$> ($ᵗ RandomTape)

/-- Decoding this sampler gives precisely reduction of the sampled wide integer. -/
theorem uniformWide_decode :
    decodeScalar <$> uniformWide =
      (fun n : RandomTape => ((n.val % curve25519.L : ℕ) : Scalar)) <$> ($ᵗ RandomTape) := by
  simp only [uniformWide, Functor.map_map]
  congr 1
  funext n
  exact decode_rawOfNat n

end DhConcrete
