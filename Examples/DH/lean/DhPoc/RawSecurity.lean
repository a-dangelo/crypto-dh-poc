import DhPoc.RawSampler

/-!
# DDH experiments for the decoded secret distributions

The sampled-DDH experiments use the caller's raw samplers and scalar decoder
for the two public values. The random branch uses an independent uniform
scalar for its challenge. These experiments need not equal standard DDH with
uniform secret scalars.

For uniform 64-byte inputs followed by reduction, the corresponding premise
is a bound on wide-sampler DDH. `Concrete.Standard` relates this experiment to
standard DDH by a proved additive statistical error.
-/

namespace DhPoc

open OracleComp OracleSpec ENNReal Aeneas.Std

variable {D S P K F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- Adapt an adversary on encodings to the group-level DDH interface. -/
def rawReduction (M : RawPrimitiveModel D S P K F G)
    (adversary : P → P → K → ProbComp Bool) : DiffieHellman.DDHAdversary F G :=
  fun _ A B T => adversary (M.point A) (M.point B) (M.key T)

/-- The real DDH branch uses the decoded values of the supplied raw samplers. -/
def sampledDDHReal (decode : S → F) (g : G) (μ ν : ProbComp S)
    (adversary : DiffieHellman.DDHAdversary F G) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  adversary g (decode a • g) (decode b • g) ((decode a * decode b) • g)

variable [SampleableType F]

/-- The random DDH branch retains the public-value distributions and samples an
independent uniform scalar for the challenge. -/
def sampledDDHRandom (decode : S → F) (g : G) (μ ν : ProbComp S)
    (adversary : DiffieHellman.DDHAdversary F G) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  let c ← $ᵗ F
  adversary g (decode a • g) (decode b • g) (c • g)

/-- The ideal session experiment retains the supplied raw-secret samplers. -/
noncomputable def sampledIdeal (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) : ProbComp Bool := do
  let a ← μ
  let b ← ν
  let c ← $ᵗ F
  match (dh_core.session M.operations a b).match with
  | .ok out => adversary out.alice_public out.bob_public (M.key (c • M.generator))
  | _ => pure false

/-- The real session experiment equals sampled DDH with the same secret distributions. -/
theorem sampledReal_eq_sampledDDHReal (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    sampledReal M μ ν adversary =
      sampledDDHReal M.scalar M.generator μ ν (rawReduction M adversary) := by
  rw [sampledReal_eq_decodedReal]
  rfl

/-- The ideal session experiment equals the random sampled-DDH branch, whose
challenge is an encoded group element. -/
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

/-- The session advantage equals the sampled-DDH advantage for the supplied
raw-secret distributions. -/
theorem sampledSessionAdvantage_eq (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) :
    sampledSessionAdvantage M μ ν adversary =
      sampledDDHAdvantage M.scalar M.generator μ ν (rawReduction M adversary) := by
  simp only [sampledSessionAdvantage, sampledReal_eq_sampledDDHReal,
    sampledIdeal_eq_sampledDDHRandom, sampledDDHAdvantage]

/-- A supplied sampled-DDH bound also bounds the session advantage.
This hypothesis differs from a bound on standard DDH with uniform secret scalars. -/
theorem sampledSessionAdvantage_le (M : RawPrimitiveModel D S P K F G)
    (μ ν : ProbComp S) (adversary : P → P → K → ProbComp Bool) (ε : ℝ≥0∞)
    (h : sampledDDHAdvantage M.scalar M.generator μ ν (rawReduction M adversary) ≤ ε) :
    sampledSessionAdvantage M μ ν adversary ≤ ε := by
  rw [sampledSessionAdvantage_eq]
  exact h

end DhPoc
