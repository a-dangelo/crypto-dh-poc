import DhPoc.PPT

/-! Separate audit for the new generic theorem family; historical audits stay unchanged. -/

namespace DhPoc.ParameterizedTests
open Aeneas.Std

instance : Fact (Nat.Prime 7) := ⟨by decide⟩

/-- Satisfiability witness only: this arithmetic group exposes its discrete logarithm,
so the model does not satisfy a DDH hardness assumption. -/
def arithmeticFamily (w : ℕ) : PrimeOrderModel Unit (ZMod 7) (ZMod 7) (ZMod 7) 7 w where
  operations := {
    «public» := fun s => .ok (s.val : ZMod 7)
    agree := fun s p => .ok ((s.val : ZMod 7) * p) }
  scalar := fun s => (s.val : ZMod 7)
  point := id
  key := id
  generator := 1
  public_spec := by intro s; simp [smul_eq_mul]
  agree_spec := by intro s p; rfl
  scalar_eq := by intro s; rfl
  generator_bijective := by simpa [smul_eq_mul] using (Function.bijective_id : Function.Bijective (id : ZMod 7 → ZMod 7))

end DhPoc.ParameterizedTests

#print axioms DhPoc.uniform_modulo_measureETVDist_le
#print axioms DhPoc.pair_bind_distance
#print axioms DhPoc.sampledDDHAdvantage_le_standard
#print axioms DhPoc.four_samplingError_le_exp
#print axioms DhPoc.four_samplingError_negligible
#print axioms DhPoc.moduloSessionAdvantage_le_standard
#print axioms DhPoc.parameterizedSessionAdvantage_negligible
#print axioms DhPoc.parameterizedSession_secure
#print axioms DhPoc.ParameterizedTests.arithmeticFamily
#print DhPoc.moduloSessionAdvantage_le_standard
#print DhPoc.parameterizedSessionAdvantage_negligible
#print DhPoc.parameterizedSession_secure

#print axioms DhPoc.PPT.precompWitness

#print axioms DhPoc.PPT.isPPTBy_precomp

#print axioms DhPoc.PPT.interpretCoins_evalDistEq

#print axioms DhPoc.PPT.ddhFamily_reduce

#print axioms DhPoc.PPT.session_secure_isPPTBy

#print DhPoc.PPT.session_secure_isPPTBy
