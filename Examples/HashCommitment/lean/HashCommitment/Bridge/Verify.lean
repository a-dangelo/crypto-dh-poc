import HashCommitment.Bridge.Representation
import HashCommitment.Model.HashCommitment

open Aeneas Aeneas.Std Result OracleComp OracleSpec
namespace HashCommitment.Bridge
open HashCommitment.Model

variable {K H R : Type}

/-- Assumption on the (abstract) Rust hash implementation, seen through the dictionary Aeneas
generated for the trait `KeyedHash<K>`: it is total and computes the pure function `hashFn`.
No property of the hash (such as collision resistance) is assumed. -/
def HashRefines (hashInst : Extracted.KeyedHash H K)
    (hashFn : K → Bytes32 → Bytes 32 → Bytes32) : Prop :=
  ∀ k m s, hashInst.hash k m s = ok (hashFn k m (toBytes s))

/-- Rust `==` on `[u8; N]`, as modelled by Aeneas, decides equality. -/
theorem array_eq_u8 {n : Usize} (a b : Aeneas.Std.Array U8 n) :
    core.array.equality.PartialEqArray.eq core.cmp.PartialEqU8 a b = ok (decide (a = b)) := by
  have hlist : ∀ (f : U8 × U8 → Result Bool), (∀ xy, f xy = ok (decide (xy.1 = xy.2))) →
      ∀ (l1 l2 : List U8), l1.length = l2.length →
      List.allM f (List.zip l1 l2) = ok (decide (l1 = l2)) := by
    intro f hf l1
    induction l1 with
    | nil => intro l2 h; cases l2 <;> simp_all; rfl
    | cons x xs ih =>
      intro l2 h
      cases l2 with
      | nil => simp at h
      | cons y ys =>
        simp only [List.length_cons, Nat.add_right_cancel_iff] at h
        simp only [List.zip_cons_cons, List.allM, hf, bind_tc_ok, List.cons.injEq]
        by_cases hxy : x = y
        · subst hxy; simp [ih ys h]
        · simp [hxy]; rfl
  unfold core.array.equality.PartialEqArray.eq
  simp only [Aeneas.Std.Array.length, Aeneas.Std.Array.length_eq, ↓reduceIte]
  rw [hlist _ (fun xy => by
    by_cases h : xy.1 = xy.2 <;> simp [h, liftFun2, core.cmp.impls.PartialEqU8.ne]) a.val b.val
    (by simp)]
  simp [Aeneas.Std.Array.eq_iff]

/-- **Verify refinement.** The extracted `verify` returns exactly the model's `verify`. -/
theorem verify_refines
    (hashInst : Extracted.KeyedHash H K) (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg c opening : Bytes32) :
    Extracted.verify hashInst key msg c opening =
      ok (Model.verify hashFn key msg c (toBytes opening)) := by
  unfold Extracted.verify
  simp [hH key msg opening, array_eq_u8, Model.verify]


end HashCommitment.Bridge

