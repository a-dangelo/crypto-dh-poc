import DhPoc.Refinement

/-!
# Preserve the caller's actual secret distribution

Wide-byte reduction is not exactly uniform modulo the group order. This layer
therefore samples the raw secret type and records its mathematical scalar value.
It proves exact implementation correspondence for that distribution, without a
claim that the distribution is uniform or that the resulting game satisfies DDH.
-/

namespace DhPoc

open OracleComp OracleSpec Aeneas.Std

variable (D S P K F G : Type) [Field F] [AddCommGroup G] [Module F G]

/-- Concrete-backend obligations for every raw secret, including noncanonical input. -/
structure RawPrimitiveModel where
  operations : dh_core.Dh D S P K
  scalar : S → F
  point : G → P
  key : G → K
  generator : G
  public_spec : ∀ s, operations.«public» s = .ok (point (scalar s • generator))
  agree_spec : ∀ s p, operations.agree s (point p) = .ok (key (scalar s • p))

variable {D S P K F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- The same extracted function refines pointwise for all raw input values. -/
theorem raw_session_refines (M : RawPrimitiveModel D S P K F G) (a b : S) :
    dh_core.session M.operations a b =
      .ok { alice_public := M.point (M.scalar a • M.generator),
            bob_public := M.point (M.scalar b • M.generator),
            alice_key := M.key ((M.scalar a * M.scalar b) • M.generator),
            bob_key := M.key ((M.scalar a * M.scalar b) • M.generator) } := by
  simp only [dh_core.session, M.public_spec, bind_ok, M.agree_spec, smul_smul,
    mul_comm (M.scalar b) (M.scalar a)]

/-- Each caller supplies a sampler on its actual Rust secret representation.
Using two samplers does not assert that the samples are uniform. -/
noncomputable def sampledReal (M : RawPrimitiveModel D S P K F G)
    (aliceSampler bobSampler : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    ProbComp Bool := do
  let a ← aliceSampler
  let b ← bobSampler
  match (dh_core.session M.operations a b).match with
  | .ok out => adversary out.alice_public out.bob_public out.alice_key
  | _ => pure false

/-- Group-level DH with the same raw samples and the exact scalar decoder. -/
def decodedReal (M : RawPrimitiveModel D S P K F G)
    (aliceSampler bobSampler : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    ProbComp Bool := do
  let a ← aliceSampler
  let b ← bobSampler
  adversary (M.point (M.scalar a • M.generator))
    (M.point (M.scalar b • M.generator))
    (M.key ((M.scalar a * M.scalar b) • M.generator))

/-- No ideal-uniform substitution occurs in this exact game equality. -/
theorem sampledReal_eq_decodedReal (M : RawPrimitiveModel D S P K F G)
    (aliceSampler bobSampler : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    sampledReal M aliceSampler bobSampler adversary =
      decodedReal M aliceSampler bobSampler adversary := by
  simp only [sampledReal, raw_session_refines, Result.match.ok, decodedReal]

end DhPoc
