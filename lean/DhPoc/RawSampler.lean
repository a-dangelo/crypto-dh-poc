import DhPoc.Refinement

/-!
# Refinement with caller-supplied secret distributions

Reduction of uniform wide bytes need not give a uniform scalar. We therefore
sample the raw secret type and record the scalar decoder. The correspondence
preserves the supplied distributions. It assumes neither uniform decoded
scalars nor a DDH bound for the resulting experiments.
-/

namespace DhPoc

open OracleComp OracleSpec Aeneas.Std

variable (D S P K F G : Type) [Field F] [AddCommGroup G] [Module F G]

/-- Representation maps and primitive contracts for every raw secret, including
noncanonical inputs. -/
structure RawPrimitiveModel where
  operations : dh_core.Dh D S P K
  scalar : S → F
  point : G → P
  key : G → K
  generator : G
  public_spec : ∀ s, operations.«public» s = .ok (point (scalar s • generator))
  agree_spec : ∀ s p, operations.agree s (point p) = .ok (key (scalar s • p))

variable {D S P K F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- The extracted session satisfies the group specification for every pair of
raw inputs under the primitive contracts. -/
theorem raw_session_refines (M : RawPrimitiveModel D S P K F G) (a b : S) :
    dh_core.session M.operations a b =
      .ok { alice_public := M.point (M.scalar a • M.generator),
            bob_public := M.point (M.scalar b • M.generator),
            alice_key := M.key ((M.scalar a * M.scalar b) • M.generator),
            bob_key := M.key ((M.scalar a * M.scalar b) • M.generator) } := by
  simp only [dh_core.session, M.public_spec, bind_ok, M.agree_spec, smul_smul,
    mul_comm (M.scalar b) (M.scalar a)]

/-- The real experiment samples each secret from its supplied distribution on
the Rust representation. Neither distribution is required to be uniform. -/
noncomputable def sampledReal (M : RawPrimitiveModel D S P K F G)
    (aliceSampler bobSampler : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    ProbComp Bool := do
  let a ← aliceSampler
  let b ← bobSampler
  match (dh_core.session M.operations a b).match with
  | .ok out => adversary out.alice_public out.bob_public out.alice_key
  | _ => pure false

/-- The group-level real experiment uses the same raw samplers and scalar decoder. -/
def decodedReal (M : RawPrimitiveModel D S P K F G)
    (aliceSampler bobSampler : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    ProbComp Bool := do
  let a ← aliceSampler
  let b ← bobSampler
  adversary (M.point (M.scalar a • M.generator))
    (M.point (M.scalar b • M.generator))
    (M.key ((M.scalar a * M.scalar b) • M.generator))

/-- The extracted and group-level experiments are equal with the supplied samplers. -/
theorem sampledReal_eq_decodedReal (M : RawPrimitiveModel D S P K F G)
    (aliceSampler bobSampler : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    sampledReal M aliceSampler bobSampler adversary =
      decodedReal M aliceSampler bobSampler adversary := by
  simp only [sampledReal, raw_session_refines, Result.match.ok, decodedReal]

end DhPoc
