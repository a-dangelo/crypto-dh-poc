import HashCommitment.IdealRng

/-! Exact probability laws for the remaining RNG methods and sequential fills. -/
namespace HashCommitment
open Aeneas.Std OracleComp OracleSpec Probability

private theorem uniform_depth (n : Nat) : (Program.uniform n).depth = 2 := by
  simp [Program.uniform, Program.depth, Finset.sup_const]

/-- Finite witness for the dictionary's 32-bit request. -/
def word32Program : Program (U32 × Unit) :=
  (Program.uniform (2^32-1)).map fun x => (⟨BitVec.ofFin x⟩, ())

/-- Finite witness for the dictionary's 64-bit request. -/
def word64Program : Program (U64 × Unit) :=
  (Program.uniform (2^64-1)).map fun x => (⟨BitVec.ofFin x⟩, ())

/-- The actual 32-bit method is uniform and returns the unit handle. -/
theorem next_u32_interpret (fuel : Nat) (h : 2 ≤ fuel) :
    interpret fuel (idealRng.next_u32 ()) = (do
      let word ← $ᵗ (BitVec 32)
      pure (Outcome.success ((⟨word⟩ : U32), ()))) := by
  have hr : idealRng.next_u32 () = word32Program.toResult := by
    simp [idealRng, word32Program]
  rw [hr, Program.interpret_toResult _ fuel (by
    simpa only [word32Program, Program.depth_map, uniform_depth] using h)]
  simp only [word32Program, Program.toProb_map, Program.toProb_uniform]
  change _ = (do let word ← BitVec.ofFin <$> ProbComp.uniformFin (2^32-1)
                 pure (Outcome.success ((⟨word⟩ : U32), ())))
  simp [map_eq_bind_pure_comp, LawfulMonad.bind_assoc]

/-- The actual 64-bit method is uniform and returns the unit handle. -/
theorem next_u64_interpret (fuel : Nat) (h : 2 ≤ fuel) :
    interpret fuel (idealRng.next_u64 ()) = (do
      let word ← $ᵗ (BitVec 64)
      pure (Outcome.success ((⟨word⟩ : U64), ()))) := by
  have hr : idealRng.next_u64 () = word64Program.toResult := by
    simp [idealRng, word64Program]
  rw [hr, Program.interpret_toResult _ fuel (by
    simpa only [word64Program, Program.depth_map, uniform_depth] using h)]
  simp only [word64Program, Program.toProb_map, Program.toProb_uniform]
  change _ = (do let word ← BitVec.ofFin <$> ProbComp.uniformFin (2^64-1)
                 pure (Outcome.success ((⟨word⟩ : U64), ())))
  simp [map_eq_bind_pure_comp, LawfulMonad.bind_assoc]

/-- Call the actual fill method twice, threading the returned RNG handle. -/
def twoFills (a b : Slice U8) : Result ((Slice U8 × Slice U8) × Unit) := do
  let (r₁, a') ← idealRng.fill_bytes () a
  let (r₂, b') ← idealRng.fill_bytes r₁ b
  Result.ok ((a', b'), r₂)

/-- Finite representation of the two dictionary calls. -/
def twoFillsProgram (a b : Slice U8) : Program ((Slice U8 × Slice U8) × Unit) :=
  (fillProgram a).bind fun first =>
    (fillProgram b).map fun second => ((first.2, second.2), second.1)

/-- The representation is equal to the actual composed interaction tree. -/
theorem twoFills_representation (a b : Slice U8) :
    twoFills a b = (twoFillsProgram a b).toResult := by
  simp only [twoFills, twoFillsProgram, Program.toResult_bind, Program.toResult_map,
    idealRng]
  congr 1

/-- Two fills use at most the total requested bytes plus one return node. -/
theorem twoFills_depth (a b : Slice U8) :
    (twoFillsProgram a b).depth ≤ a.length + b.length + 1 := by
  apply le_trans (Program.depth_bind_le_add _ _ b.length ?_) (by
    have ha := fillProgram_depth a
    omega)
  intro first
  simpa using fillProgram_depth b

/-- The actual consecutive calls return independent uniformly sampled buffers. -/
theorem twoFills_interpret (a b : Slice U8) (fuel : Nat)
    (h : a.length + b.length + 1 ≤ fuel) :
    interpret fuel (twoFills a b) = (do
      let pair ← $ᵗ (Model.Bytes a.length × Model.Bytes b.length)
      pure (Outcome.success ((vectorSlice pair.1 a.property,
        vectorSlice pair.2 b.property), ()))) := by
  rw [twoFills_representation, Program.interpret_toResult _ fuel
    ((twoFills_depth a b).trans h)]
  simp [twoFillsProgram, Program.toProb_bind, fillProgram_toProb,
    SampleableType.uniformSample_prod_eq_bind]

end HashCommitment
