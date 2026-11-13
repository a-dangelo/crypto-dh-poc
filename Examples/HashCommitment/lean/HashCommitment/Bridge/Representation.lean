import Aeneas
import HashCommitment.Generated.HashCommitment
import HashCommitment.Model.Rng

/-! Representation conversions between extracted arrays and model byte vectors. -/
open Aeneas Aeneas.Std Result
open HashCommitment.Model
namespace HashCommitment.Bridge

/-- 32 bytes at Aeneas's array type: the Rust `[u8; 32]`. -/
abbrev Bytes32 := Aeneas.Std.Array U8 32#usize

/-- Read an Aeneas byte array as model bytes. -/
def toBytes {n : Usize} (a : Aeneas.Std.Array U8 n) : Bytes n.val :=
  ⟨(a.val.map (·.bv)).toArray, by simp⟩

/-- Read model bytes as an Aeneas byte array. -/
def ofBytes {n : Usize} (v : Bytes n.val) : Aeneas.Std.Array U8 n :=
  Aeneas.Std.Array.from (v.toList.map (⟨·⟩)) (by simp)

@[simp] theorem toBytes_ofBytes {n : Usize} (v : Bytes n.val) : toBytes (ofBytes v) = v := by
  ext i hi; simp [toBytes, ofBytes]

@[simp] theorem ofBytes_toBytes {n : Usize} (a : Aeneas.Std.Array U8 n) :
    ofBytes (toBytes a) = a := by
  simp only [Aeneas.Std.Array.eq_iff, toBytes, ofBytes, Aeneas.Std.Array.from_val,
    Vector.toList_mk, List.map_map]
  exact (List.map_congr_left (fun _ _ => rfl)).trans (List.map_id _)


end HashCommitment.Bridge

