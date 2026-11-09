import DhPoc.Games
import Mathlib.Algebra.Field.ZMod

/-!
# Insecure, executable arithmetic witness and negative regression

This seven-element model proves that the primitive contracts are satisfiable.
It is deliberately NOT a cryptographic backend: the public value reveals the
secret, and DDH is easy. It validates the extracted control-flow bridge only.
-/

namespace DhPoc.Examples

open Aeneas Aeneas.Std

instance : Fact (Nat.Prime 7) := ⟨by decide⟩

abbrev Scalar := ZMod 7

/-- Identity public representation: deliberately insecure. -/
def arithmeticOps : dh_core.Dh Unit Scalar Scalar Scalar where
  «public» a := .ok a
  agree a p := .ok (a * p)

/-- A concrete inhabitant of all the abstract primitive contracts. -/
def arithmeticModel : PrimitiveModel Unit Scalar Scalar Scalar Scalar Scalar where
  operations := arithmeticOps
  secret := id
  point := id
  key := id
  generator := 1
  public_spec a := by simp [arithmeticOps, smul_eq_mul]
  agree_spec a p := by simp [arithmeticOps, smul_eq_mul]

/-- The actual generated session returns the expected two public values and keys. -/
theorem session_two_three :
    dh_core.session arithmeticOps 2 3 =
      .ok { alice_public := 2, bob_public := 3,
            alice_key := 6, bob_key := 6 } := by
  have h : (2 : Scalar) * 3 = 6 := by decide
  simpa [arithmeticModel, smul_eq_mul, h] using session_refines arithmeticModel 2 3

/-- A failing primitive for checking the extracted program's failure propagation. -/
def failingOps : dh_core.Dh Unit Scalar Scalar Scalar where
  «public» _ := .fail .panic
  agree a p := .ok (a * p)

/-- A failing first primitive remains a failure in the extracted program. -/
theorem session_preserves_failure (a b : Scalar) :
    dh_core.session failingOps a b = .fail .panic := by
  simp [dh_core.session, failingOps, Aeneas.Std.bind_fail]

/-- The failing primitive cannot satisfy even the public primitive contract. -/
theorem failing_public_not_ok (a p : Scalar) :
    failingOps.«public» a ≠ .ok p := by
  intro h
  have hm := congrArg Aeneas.Std.Result.match h
  simp [failingOps] at hm

end DhPoc.Examples
