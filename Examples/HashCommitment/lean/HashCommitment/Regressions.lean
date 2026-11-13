import HashCommitment.IdealRng
import VCVio.OracleComp.Constructions.SampleableType.Measure
import VCVio.OracleComp.EvalDist.Sum

namespace HashCommitment.Regressions
open OracleComp OracleSpec Model
open scoped ENNReal

/-- The equality test for two independent byte samples. -/
def freshLaw : ProbComp Bool := do
  let x ← $ᵗ Model.Byte
  let y ← $ᵗ Model.Byte
  pure (x == y)

/-- The same byte is deliberately returned twice before testing equality. -/
def reusedLaw : ProbComp Bool := do
  let x ← $ᵗ Model.Byte
  pure (x == x)

/-- Independent bytes coincide with probability exactly one in 256. -/
theorem fresh_probability : Pr{let b ← freshLaw}[b = true] = 1 / 256 := by
  simp only [freshLaw, prEvent_norm]
  rw [prEvent_bind_eq_tsum_prEvent]
  simp [Finset.filter_eq, Finset.filter_eq']
  rw [← mul_assoc, ENNReal.mul_inv_cancel (by norm_num) (by norm_num), one_mul]

/-- Reusing a single sampled byte makes the equality test certain. -/
theorem reused_probability : Pr{let b ← reusedLaw}[b = true] = 1 := by
  simp [reusedLaw]

/-- Testing a uniformly sampled byte for zero has probability one in 256. -/
theorem branch_probability : Pr{let x ← $ᵗ Model.Byte}[x = 0] = 1 / 256 := by
  rw [SampleableType.prEvent_uniformSample_eq_singleton]
  simp

open Aeneas Aeneas.Std Probability Probability.Program

private theorem fill_one (b : U8) :
    idealRng.fill_bytes () (Array.to_slice (Array.repeat 1#usize b)) =
      (byteProgram.map fun x => ((), vectorSlice #v[x] (by scalar_tac))).toResult := rfl

/-- Finite witness for the two generated fill calls, including the returned RNG handle. -/
def freshWitness : Program ((U8 × U8) × Unit) :=
  byteProgram.bind fun x => byteProgram.map fun y => ((⟨x⟩, ⟨y⟩), ())

/-- Finite witness for one generated fill whose answer is reused. -/
def reusedWitness : Program ((U8 × U8) × Unit) :=
  byteProgram.map fun x => ((⟨x⟩, ⟨x⟩), ())

/-- The finite witness equals the actual two-call extracted Rust function. -/
theorem extracted_fresh :
    Extracted.fresh_draws idealRng idealCryptoRng () = freshWitness.toResult := by
  simp [Extracted.fresh_draws, Aeneas.Std.Array.to_slice_mut, Aeneas.Std.lift,
    fill_one, freshWitness, byteProgram, Program.map, Program.bind, Program.toResult,
    Aeneas.Std.Array.from_slice, Aeneas.Std.Array.index_usize, vectorSlice]

/-- The finite witness equals the actual one-call extracted Rust function. -/
theorem extracted_reused :
    Extracted.reused_draw idealRng idealCryptoRng () = reusedWitness.toResult := by
  simp [Extracted.reused_draw, Aeneas.Std.Array.to_slice_mut, Aeneas.Std.lift,
    fill_one, reusedWitness, byteProgram, Program.map, Program.bind, Program.toResult,
    Aeneas.Std.Array.from_slice, Aeneas.Std.Array.index_usize, vectorSlice]

/-- The generated branch has two outcomes determined by its one sampled byte. -/
def branchWitness : Program (Bool × Unit) :=
  byteProgram.map fun x => (decide (x = 0), ())

/-- The witness retains the actual generated conditional. -/
theorem extracted_branch :
    Extracted.branch_draw idealRng idealCryptoRng () = branchWitness.toResult := by
  simp [Extracted.branch_draw, Aeneas.Std.Array.to_slice_mut, Aeneas.Std.lift,
    fill_one, branchWitness, byteProgram, Program.map, Program.bind, Program.toResult,
    Aeneas.Std.Array.from_slice, Aeneas.Std.Array.index_usize, vectorSlice]
  congr 1
  funext x
  simp [UScalar.ofNatCore]
  split <;> simp_all

/-- The actual generated empty-buffer call returns without a random event. -/
theorem extracted_empty : Extracted.empty_draw idealRng idealCryptoRng () = Result.ok () := by
  simp [Extracted.empty_draw, Aeneas.Std.Array.to_slice_mut, Aeneas.Std.lift,
    ]
  rw [fill_empty _ (by rfl)]
  simp


/-- Equality of the two returned bytes; exceptional outcomes do not satisfy the event. -/
def equalBytes : Outcome ((U8 × U8) × Unit) → Prop
  | .success ((x, y), _) => x = y
  | _ => False

/-- Acceptance of the generated branch; exceptional outcomes do not satisfy the event. -/
def branchTrue : Outcome (Bool × Unit) → Prop
  | .success (b, _) => b = true
  | _ => False

/-- The canonical semantics of the actual fresh-call Rust regression. -/
theorem extracted_fresh_probability :
    Pr{let x ← interpret 3 (Extracted.fresh_draws idealRng idealCryptoRng ())}[equalBytes x] =
      1 / 256 := by
  rw [extracted_fresh, Program.interpret_toResult _ 3 (by
    simp [freshWitness, byteProgram, Program.map, Program.bind, Program.depth, Finset.sup_const, Finset.univ_nonempty])]
  simpa [freshWitness, Program.toProb_bind, Program.toProb_map, equalBytes,
    freshLaw, prEvent_norm] using fresh_probability

/-- The canonical semantics distinguishes one draw reused twice from two fresh draws. -/
theorem extracted_reused_probability :
    Pr{let x ← interpret 2 (Extracted.reused_draw idealRng idealCryptoRng ())}[equalBytes x] =
      1 := by
  rw [extracted_reused, Program.interpret_toResult _ 2 (by
    simp [reusedWitness, byteProgram, Program.map, Program.bind, Program.depth, Finset.sup_const, Finset.univ_nonempty])]
  simp [reusedWitness, Program.toProb_map, equalBytes]

/-- The generated conditional is taken with probability exactly one in 256. -/
theorem extracted_branch_probability :
    Pr{let x ← interpret 2 (Extracted.branch_draw idealRng idealCryptoRng ())}[branchTrue x] =
      1 / 256 := by
  rw [extracted_branch, Program.interpret_toResult _ 2 (by
    simp [branchWitness, byteProgram, Program.map, Program.bind, Program.depth, Finset.sup_const, Finset.univ_nonempty])]
  simpa [branchWitness, Program.toProb_map, branchTrue, prEvent_norm] using branch_probability

/-- The canonical semantics of the generated zero-length request has unit success mass. -/
theorem extracted_empty_probability :
    Pr{let x ← interpret 1 (Extracted.empty_draw idealRng idealCryptoRng ())}[x = .success ()] =
      1 := by
  rw [extracted_empty]
  simp [interpret]

end HashCommitment.Regressions
