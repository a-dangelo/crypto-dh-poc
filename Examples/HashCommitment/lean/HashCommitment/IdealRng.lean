import HashCommitment.Probability
import HashCommitment.Bridge.Representation

/-!
# Ideal entropy at the extracted RNG interface

Each byte is one random event in `Result`. The handle carries no state; freshness is
provided by successive effects, not by `CryptoRng` or by the handle's type.
-/
namespace HashCommitment
open Aeneas Aeneas.Std OracleComp OracleSpec
open Probability Model Bridge

/-- One uniform byte, represented by one effect with 256 possible answers. -/
def byteProgram : Program Model.Byte :=
  .sample 255 (fun x => .pure (BitVec.ofFin x))

/-- Independent bytes in the same order as VCV-io's vector sampler. -/
def bytesProgram : (n : Nat) → Program (Model.Bytes n)
  | 0 => .pure #v[]
  | n + 1 => (bytesProgram n).bind fun v =>
      byteProgram.bind fun b => .pure (v.push b)

@[simp] theorem bytesProgram_zero : bytesProgram 0 = .pure #v[] := rfl

/-- A singleton request contains one effect, followed by its returned byte. -/
theorem bytesProgram_one : bytesProgram 1 = byteProgram.map (fun b => #v[b]) := rfl

/-- One byte has VCV-io's canonical uniform law. -/
@[simp] theorem byteProgram_toProb : byteProgram.toProb = ($ᵗ Model.Byte) := by
  change (do let x ← ProbComp.uniformFin 255; pure (BitVec.ofFin x : BitVec 8)) =
    ((fun x => (BitVec.ofFin x : BitVec 8)) <$> ProbComp.uniformFin 255)
  simp [map_eq_bind_pure_comp]

/-- The finite witness samples precisely the standard vector distribution. -/
@[simp] theorem bytesProgram_toProb (n : Nat) :
    (bytesProgram n).toProb = ($ᵗ (Model.Bytes n)) := by
  induction n with
  | zero => rfl
  | succ n ih =>
      simp only [bytesProgram, Program.toProb_bind, ih, byteProgram_toProb,
        Program.toProb]
      change _ = Vector.push <$> ($ᵗ (Model.Bytes n)) <*> ($ᵗ Model.Byte)
      simp [seq_eq_bind_map, map_eq_bind_pure_comp, LawfulMonad.bind_assoc]

/-- A request for `n` bytes needs at most `n + 1` interpretation nodes. -/
theorem bytesProgram_depth (n : Nat) : (bytesProgram n).depth ≤ n + 1 := by
  induction n with
  | zero => simp [bytesProgram, Program.depth]
  | succ n ih =>
      apply le_trans (Program.depth_bind_le_add _ _ 1 ?_) (by omega)
      intro v
      simp [byteProgram, Program.bind, Program.depth, Finset.sup_const]

/-- Successive requests have the product law, not a shared random answer. -/
theorem bytesProgram_product (m n : Nat) :
    ((bytesProgram m).bind fun x => (bytesProgram n).map (fun y => (x, y))).toProb =
      ($ᵗ (Model.Bytes m × Model.Bytes n)) := by
  simp only [Program.toProb_bind, Program.toProb_map, bytesProgram_toProb]
  exact (SampleableType.uniformSample_prod_eq_bind _ _).symm

/-- Encode a model vector as an extracted mutable slice. -/
def vectorSlice {n : Nat} (v : Model.Bytes n) (h : n ≤ Usize.max) : Slice U8 :=
  Slice.from (v.toList.map (fun b => (⟨b⟩ : U8))) (by simpa using h)

@[simp] theorem vectorSlice_length {n : Nat} (v : Model.Bytes n) (h : n ≤ Usize.max) :
    (vectorSlice v h).length = n := by simp [vectorSlice, Slice.length]

/-- A bounded byte count determines the complete fill program. -/
def fillSizedProgram (size : {n : Nat // n ≤ Usize.max}) : Program (Unit × Slice U8) :=
  (bytesProgram size.val).bind fun v => .pure ((), vectorSlice v size.property)

/-- Filling uses only the requested length, never any previous buffer contents. -/
def fillProgram (buf : Slice U8) : Program (Unit × Slice U8) :=
  fillSizedProgram ⟨buf.length, buf.property⟩

/-- Every output byte is the corresponding newly sampled byte. -/
@[simp] theorem vectorSlice_val {n : Nat} (v : Model.Bytes n) (h : n ≤ Usize.max) :
    (vectorSlice v h).val = v.toList.map (fun b => (⟨b⟩ : U8)) := by
  simp [vectorSlice]

/-- Full joint law of a fill: the handle is unit and every output byte is fresh. -/
theorem fillProgram_toProb (buf : Slice U8) :
    (fillProgram buf).toProb = (do
      let v ← $ᵗ (Model.Bytes buf.length)
      pure ((), vectorSlice v (by simp [Slice.length]))) := by
  simp [fillProgram, fillSizedProgram, Program.toProb_bind, Program.toProb]

/-- The bound depends on the requested length, not on its old contents. -/
theorem fillProgram_depth (buf : Slice U8) :
    (fillProgram buf).depth ≤ buf.length + 1 := by
  change ((bytesProgram buf.length).map _).depth ≤ _
  simpa using bytesProgram_depth buf.length

/-- The ideal source dictionary used at the actual generated trait call. -/
def idealRng : Extracted.rand_core.RngCore Unit where
  next_u32 _ := Result.uniform (2^32 - 1) >>= fun x => Result.ok (⟨BitVec.ofFin x⟩, ())
  next_u64 _ := Result.uniform (2^64 - 1) >>= fun x => Result.ok (⟨BitVec.ofFin x⟩, ())
  fill_bytes _ buf := (fillProgram buf).toResult

/-- The marker trait refers to exactly the same ideal dictionary. -/
def idealCryptoRng : Extracted.rand_core.CryptoRng Unit := ⟨idealRng⟩

/-- Adequate interpretation exposes exactly the full fill law, without discarded mass. -/
theorem fill_interpret (buf : Slice U8) (fuel : Nat) (h : buf.length + 1 ≤ fuel) :
    Probability.interpret fuel (idealRng.fill_bytes () buf) = (do
      let v ← $ᵗ (Model.Bytes buf.length)
      pure (Probability.Outcome.success
        ((), vectorSlice v (by simp [Slice.length])))) := by
  rw [show idealRng.fill_bytes () buf = (fillProgram buf).toResult from rfl,
    Program.interpret_toResult _ fuel ((fillProgram_depth buf).trans h),
    fillProgram_toProb]
  simp

/-- The ideal dictionary is independent of the old contents of equal-length buffers. -/
theorem fill_contents_independent (a b : Slice U8) (h : a.length = b.length) :
    idealRng.fill_bytes () a = idealRng.fill_bytes () b := by
  have hs : (⟨a.length, a.property⟩ : {n : Nat // n ≤ Usize.max}) =
      ⟨b.length, b.property⟩ := Subtype.ext h
  exact congrArg (fun size => (fillSizedProgram size).toResult) hs

/-- A zero-length request returns its unchanged empty buffer without sampling. -/
theorem fill_empty (buf : Slice U8) (h : buf.length = 0) :
    idealRng.fill_bytes () buf = Result.ok ((), buf) := by
  cases buf with
  | mk n l hn =>
    simp only [Slice.length, Slice.val, Aeneas.Data.ListN.ListN_length] at h
    subst n
    cases l
    rfl

end HashCommitment
