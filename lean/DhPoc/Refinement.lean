import DhPoc.Generated.DhCore
import VCVio.CryptoFoundations.HardnessAssumptions.DiffieHellman

/-!
# The explicit boundary between extracted control flow and group arithmetic

The two equations below are hypotheses, not axioms. The native Ristretto adapter
has not yet been proved to satisfy them. The theorem checks every protocol call
in the Aeneas output. It does not identify the Rust code with a handwritten spec.
-/

namespace DhPoc

open Aeneas Aeneas.Std

variable (D S P K F G : Type) [Field F] [AddCommGroup G] [Module F G]

/-- Contracts required from a concrete group backend and its representations. -/
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

/-- Exact successful output of the generated Rust program, under primitive contracts.
No probability or cryptographic hardness assumption is used here. -/
theorem session_refines (M : PrimitiveModel D S P K F G) (a b : F) :
    dh_core.session M.operations (M.secret a) (M.secret b) =
      .ok { alice_public := M.point (a • M.generator),
            bob_public := M.point (b • M.generator),
            alice_key := M.key ((a * b) • M.generator),
            bob_key := M.key ((a * b) • M.generator) } := by
  simp only [dh_core.session, M.public_spec, Aeneas.Std.bind_ok,
    M.agree_spec, smul_smul, mul_comm b a]

/-- Both honest parties return the same encoded group element. -/
theorem honest_agreement (M : PrimitiveModel D S P K F G) (a b : F) :
    ∃ out, dh_core.session M.operations (M.secret a) (M.secret b) = .ok out ∧
      out.alice_key = out.bob_key := by
  exact ⟨_, session_refines M a b, rfl⟩

end DhPoc
