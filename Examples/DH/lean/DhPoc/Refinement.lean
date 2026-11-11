import DhPoc.Generated.DhCore
import VCVio.CryptoFoundations.HardnessAssumptions.DiffieHellman

/-!
# Refinement from extracted control flow to group operations

The structure `PrimitiveModel` records the representation maps and the two
primitive contracts used by `session_refines`. These contracts are hypotheses
of the generic theorem. The proof follows the calls in the Aeneas translation
`dh_core.session`.

The concrete construction in `Concrete.Model` proves the corresponding
`RawPrimitiveModel` contracts for the pinned Ristretto backend.
`Concrete.Native` then relates those operations to the extracted Rust wrapper
for the selected backend configuration. The earlier adapter in `rust/native`
remains outside that extraction proof.
-/

namespace DhPoc

open Aeneas Aeneas.Std

variable (D S P K F G : Type) [Field F] [AddCommGroup G] [Module F G]

/-- Representation maps and correctness contracts for a group implementation. -/
structure PrimitiveModel where
  operations : dh_core.Dh D S P K
  secret : F → S
  point : G → P
  key : G → K
  generator : G
  public_spec : ∀ a, operations.«public» (secret a) =
    .ok (point (a • generator))
  agree_spec : ∀ a p, operations.agree (secret a) (point p) =
    .ok (key (a • p))

variable {D S P K F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- The extracted session returns the stated public values and shared keys under
the primitive contracts. The theorem uses no probability or hardness hypothesis. -/
theorem session_refines (M : PrimitiveModel D S P K F G) (a b : F) :
    dh_core.session M.operations (M.secret a) (M.secret b) =
      .ok { alice_public := M.point (a • M.generator),
            bob_public := M.point (b • M.generator),
            alice_key := M.key ((a * b) • M.generator),
            bob_key := M.key ((a * b) • M.generator) } := by
  simp only [dh_core.session, M.public_spec, Aeneas.Std.bind_ok,
    M.agree_spec, smul_smul, mul_comm b a]

/-- Both honest participants obtain the same encoded group element. -/
theorem honest_agreement (M : PrimitiveModel D S P K F G) (a b : F) :
    ∃ out, dh_core.session M.operations (M.secret a) (M.secret b) = .ok out ∧
      out.alice_key = out.bob_key := by
  exact ⟨_, session_refines M a b, rfl⟩

end DhPoc
