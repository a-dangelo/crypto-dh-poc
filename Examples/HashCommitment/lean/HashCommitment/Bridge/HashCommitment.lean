import HashCommitment.IdealRng
import HashCommitment.Bridge.Verify
import HashCommitment.Model.Security

/-!
# Refinement of the extracted commitment

The finite witness below describes the whole returned value, including the opening and
RNG handle. Its connection to Rust is the equality `commit_representation`, not its type.
-/
namespace HashCommitment.Bridge
open Aeneas Aeneas.Std Result OracleComp OracleSpec
open Probability Model
variable {K H : Type}

/-- A finite witness for the complete output of the extracted commitment. -/
def commitProgram (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (key : K) (msg : Bytes32) : Program ((Bytes32 × Bytes32) × Unit) :=
  (bytesProgram 32).map fun opening =>
    ((hashFn key msg opening, ofBytes opening), ())

/-- Writing a sampled vector back to an array replaces every byte. -/
theorem from_slice_vector {n : Usize} (a : Aeneas.Std.Array U8 n)
    (v : Bytes n.val) (h : n.val ≤ Usize.max) :
    a.from_slice (vectorSlice v h) = ofBytes v := by
  apply Aeneas.Std.Array.ext
  simp [Aeneas.Std.Array.from_slice, vectorSlice, ofBytes]

/-- The mutable view requests exactly the array's byte count. -/
theorem fill_array {n : Usize} (a : Aeneas.Std.Array U8 n) :
    fillProgram a.to_slice = fillSizedProgram ⟨n.val, by scalar_tac⟩ := by
  apply congrArg fillSizedProgram
  apply Subtype.ext
  simp [Aeneas.Std.Array.to_slice, Slice.length]

/-- The actual generated term equals the finite sampling witness, including its handle. -/
theorem commit_representation
    (hashInst : Extracted.KeyedHash H K)
    (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg : Bytes32) :
    Extracted.commit hashInst idealRng idealCryptoRng key msg () =
      (commitProgram hashFn key msg).toResult := by
  simp only [Extracted.commit, Aeneas.Std.Array.to_slice_mut, lift, bind_ok]
  change (do
    let (rng1, s1) ← idealRng.fill_bytes () (Aeneas.Std.Array.repeat 32#usize 0#u8).to_slice
    let c ← hashInst.hash key msg ((Aeneas.Std.Array.repeat 32#usize 0#u8).from_slice s1)
    ok ((c, (Aeneas.Std.Array.repeat 32#usize 0#u8).from_slice s1), rng1)) = _
  simp only [idealRng, fill_array, fillSizedProgram, Program.toResult_bind,
    Program.toResult, commitProgram, Program.toResult_map, bind_tc_eq, Aeneas.Std.bind_assoc, bind_ok]
  congr 1
  funext opening
  simp only [from_slice_vector]
  rw [hH key msg (ofBytes opening)]
  simp

/-- Thirty-two byte events and one return node suffice. -/
theorem commit_depth (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (key : K) (msg : Bytes32) : (commitProgram hashFn key msg).depth ≤ 33 := by
  simpa [commitProgram] using bytesProgram_depth 32

/-- Joint law of digest, opening and handle, with no discarded failure mass. -/
theorem commit_joint_law
    (hashInst : Extracted.KeyedHash H K)
    (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg : Bytes32)
    (fuel : Nat) (hf : (commitProgram hashFn key msg).depth ≤ fuel) :
    Probability.interpret fuel (Extracted.commit hashInst idealRng idealCryptoRng key msg ()) =
      (do let output ← (commitProgram hashFn key msg).toProb
          pure (Probability.Outcome.success output)) := by
  exact Probability.interpret_eq_of_representation _ _
    (commit_representation hashInst hashFn hH key msg) fuel hf

/-- The full generated output has the abstract uniform-opening law. -/
theorem commit_uniform_joint_law
    (hashInst : Extracted.KeyedHash H K)
    (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg : Bytes32)
    (fuel : Nat) (hf : 33 ≤ fuel) :
    Probability.interpret fuel (Extracted.commit hashInst idealRng idealCryptoRng key msg ()) =
      (do let opening ← $ᵗ (Bytes 32)
          pure (Probability.Outcome.success ((hashFn key msg opening, ofBytes opening), ()))) := by
  rw [commit_joint_law hashInst hashFn hH key msg fuel
    ((commit_depth hashFn key msg).trans hf)]
  simp only [commitProgram, Program.toProb_map, bytesProgram_toProb,
    LawfulMonad.bind_assoc, LawfulMonad.pure_bind]

/-- The joint law composes with any probabilistic continuation on the returned value. -/
theorem commit_continuation {α : Type}
    (hashInst : Extracted.KeyedHash H K)
    (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg : Bytes32)
    (fuel : Nat) (hf : (commitProgram hashFn key msg).depth ≤ fuel)
    (next : Probability.Outcome ((Bytes32 × Bytes32) × Unit) → ProbComp α) :
    (Probability.interpret fuel
      (Extracted.commit hashInst idealRng idealCryptoRng key msg ()) >>= next) =
      (do let output ← (commitProgram hashFn key msg).toProb
          next (.success output)) := by
  rw [commit_joint_law hashInst hashFn hH key msg fuel hf]
  simp only [LawfulMonad.bind_assoc, LawfulMonad.pure_bind]

end HashCommitment.Bridge
