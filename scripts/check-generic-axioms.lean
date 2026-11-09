import DhPoc.RawSecurity
import DhPoc.Games
import DhPoc.RawSampler
import Mathlib.Algebra.Field.ZMod

/-!
# Arithmetic witnesses and failure regressions

The seven-element model witnesses satisfiability of the primitive contracts.
Its public value reveals the secret, so DDH is easy in this model.
The examples check the extracted control flow and failure propagation.
-/

namespace DhPoc.Examples

open Aeneas Aeneas.Std

instance : Fact (Nat.Prime 7) := ⟨by decide⟩

abbrev Scalar := ZMod 7

/-- Operations with an identity public representation, which reveals the secret. -/
def arithmeticOps : dh_core.Dh Unit Scalar Scalar Scalar where
  «public» a := .ok a
  agree a p := .ok (a * p)

/-- An arithmetic model that satisfies the abstract primitive contracts. -/
def arithmeticModel : PrimitiveModel Unit Scalar Scalar Scalar Scalar Scalar where
  operations := arithmeticOps
  secret := id
  point := id
  key := id
  generator := 1
  public_spec a := by simp [arithmeticOps, smul_eq_mul]
  agree_spec a p := by simp [arithmeticOps, smul_eq_mul]

/-- The extracted session returns the specified public values and keys for inputs 2 and 3. -/
theorem session_two_three :
    dh_core.session arithmeticOps 2 3 =
      .ok { alice_public := 2, bob_public := 3,
            alice_key := 6, bob_key := 6 } := by
  have h : (2 : Scalar) * 3 = 6 := by decide
  simpa [arithmeticModel, smul_eq_mul, h] using session_refines arithmeticModel 2 3

/-- Operations whose public-value computation fails, used to test failure propagation. -/
def failingOps : dh_core.Dh Unit Scalar Scalar Scalar where
  «public» _ := .fail .panic
  agree a p := .ok (a * p)

/-- The extracted session preserves failure of the first public-value computation. -/
theorem session_preserves_failure (a b : Scalar) :
    dh_core.session failingOps a b = .fail .panic := by
  simp [dh_core.session, failingOps, Aeneas.Std.bind_fail]

/-- The failing public-value computation cannot satisfy the public primitive contract. -/
theorem failing_public_not_ok (a p : Scalar) :
    failingOps.«public» a ≠ .ok p := by
  intro h
  have hm := congrArg Aeneas.Std.Result.match h
  simp [failingOps] at hm

end DhPoc.Examples

-- Check transitive kernel-axiom dependencies of every claimed bridge theorem.
#print axioms DhPoc.session_refines
#print axioms DhPoc.honest_agreement
#print axioms DhPoc.realExperiment_eq_ddhRealExperiment
#print axioms DhPoc.idealExperiment_eq_ddhRandomExperiment
#print axioms DhPoc.sessionAdvantage_eq_ddhAdvantage
#print axioms DhPoc.sessionAdvantage_le_of_ddh

#print axioms DhPoc.raw_session_refines
#print axioms DhPoc.sampledReal_eq_decodedReal
#print axioms DhPoc.Examples.arithmeticModel
#print axioms DhPoc.Examples.session_two_three
#print axioms DhPoc.Examples.session_preserves_failure
#print axioms DhPoc.Examples.failing_public_not_ok

#print axioms DhPoc.sampledReal_eq_sampledDDHReal
#print axioms DhPoc.sampledIdeal_eq_sampledDDHRandom
#print axioms DhPoc.sampledSessionAdvantage_eq
#print axioms DhPoc.sampledSessionAdvantage_le
