import DhPoc.RawSampler

/-!
# A DDH assumption for the actual scalar distribution

This is a separate, explicitly named sampled-DDH game. Its two public secrets
come from the caller's raw samplers and decoder. The random challenge uses an
independent uniform scalar. No equality to standard uniform-secret DDH is claimed.
For a 64-byte uniform sampler plus reduction, this is a wide-sampler DDH premise.
-/

namespace DhPoc

open OracleComp OracleSpec ENNReal Aeneas.Std

variable {D S P K F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- The same encoding adapter as for ordinary DDH. -/
def rawReduction (M : RawPrimitiveModel D S P K F G)
    (adversary : P → P → K → ProbComp Bool) : DiffieHellman.DDHAdversary F G :=
  fun _ A B T => adversary (M.point A) (M.point B) (M.key T)

/-- Mathematical DDH real branch with the actual raw-secret distributions. -/
def sampledDDHReal (decode : S → F) (g : G) (μ ν : ProbComp S)
    (adversary : DiffieHellman.DDHAdversary F G) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  adversary g (decode a • g) (decode b • g) ((decode a * decode b) • g)

variable [SampleableType F]

/-- Mathematical random branch: same public distribution, independent uniform challenge. -/
def sampledDDHRandom (decode : S → F) (g : G) (μ ν : ProbComp S)
    (adversary : DiffieHellman.DDHAdversary F G) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  let c ← $ᵗ F
  adversary g (decode a • g) (decode b • g) (c • g)

/-- Ideal implementation game, including its actual raw public-secret samplers. -/
noncomputable def sampledIdeal (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  let c ← $ᵗ F
  match (dh_core.session M.operations a b).match with
  | .ok out => adversary out.alice_public out.bob_public (M.key (c • M.generator))
  | _ => pure false

/-- Exact real-branch bridge without changing the secret distribution. -/
theorem sampledReal_eq_sampledDDHReal (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    sampledReal M μ ν adversary =
      sampledDDHReal M.scalar M.generator μ ν (rawReduction M adversary) := by
  rw [sampledReal_eq_decodedReal]
  rfl

/-- Exact ideal-branch bridge; the challenge remains an encoded group element. -/
theorem sampledIdeal_eq_sampledDDHRandom (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    sampledIdeal M μ ν adversary =
      sampledDDHRandom M.scalar M.generator μ ν (rawReduction M adversary) := by
  simp only [sampledIdeal, raw_session_refines, Result.match.ok,
    sampledDDHRandom, rawReduction]

noncomputable def sampledDDHAdvantage (decode : S → F) (g : G) (μ ν : ProbComp S)
    (adversary : DiffieHellman.DDHAdversary F G) : ℝ≥0∞ :=
  𝒟[sampledDDHReal decode g μ ν adversary].boolDist
    𝒟[sampledDDHRandom decode g μ ν adversary]

noncomputable def sampledSessionAdvantage (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) : ℝ≥0∞ :=
  𝒟[sampledReal M μ ν adversary].boolDist 𝒟[sampledIdeal M μ ν adversary]

/-- Exact security transport for the explicitly supplied raw-secret distribution. -/
theorem sampledSessionAdvantage_eq (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    sampledSessionAdvantage M μ ν adversary =
      sampledDDHAdvantage M.scalar M.generator μ ν (rawReduction M adversary) := by
  simp only [sampledSessionAdvantage, sampledReal_eq_sampledDDHReal,
    sampledIdeal_eq_sampledDDHRandom, sampledDDHAdvantage]

/-- A sampled-DDH bound is a different hypothesis from standard uniform-secret DDH. -/
theorem sampledSessionAdvantage_le (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) (ε : ℝ≥0∞)
    (h : sampledDDHAdvantage M.scalar M.generator μ ν (rawReduction M adversary) ≤ ε) :
    sampledSessionAdvantage M μ ν adversary ≤ ε := by
  rw [sampledSessionAdvantage_eq]
  exact h

end DhPoc
