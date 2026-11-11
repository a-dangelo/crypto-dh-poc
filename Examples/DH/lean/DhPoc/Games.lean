import DhPoc.Refinement
import VCVio.CryptoFoundations.HardnessAssumptions.DiffieHellman

/-!
# Exact correspondence between the extracted session and VCVio DDH

The experiments execute the Aeneas translation `dh_core.session`.
They return `false` on every non-success result. The contracts in
`PrimitiveModel` exclude those results for encoded scalar inputs.
The ideal challenge is the encoding of a group element sampled independently
of the public values. It is not a uniform byte string.

These generic results require neither injective encodings nor a hash or KDF
assumption. They do not establish authentication or the correctness of a
concrete curve implementation.
-/

namespace DhPoc

open OracleComp OracleSpec ENNReal

variable {D S P K F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- A probabilistic adversary that observes two public encodings and one key encoding. -/
abbrev SessionAdversary (P K : Type) := P → P → K → ProbComp Bool

/-- Adapt an adversary on encodings to VCVio's group-level DDH interface.
The model fixes the public generator, so the adapter ignores that argument. -/
def ddhReduction (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : DiffieHellman.DDHAdversary F G :=
  fun _ A B T => adversary (M.point A) (M.point B) (M.key T)

section Experiments

variable [SampleableType F]

/-- The real passive experiment runs the extracted session and reveals Alice's key.
The refinement theorem proves that Bob obtains the same key. -/
def realExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : ProbComp Bool := do
  let a ← $ᵗ F
  let b ← $ᵗ F
  match (dh_core.session M.operations (M.secret a) (M.secret b)).match with
  | .ok session => adversary session.alice_public session.bob_public session.alice_key
  | _ => pure false

/-- The ideal passive experiment runs the extracted session and replaces the
challenge with an independent encoding of `c • generator`. It retains failure cases. -/
def idealExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : ProbComp Bool := do
  let a ← $ᵗ F
  let b ← $ᵗ F
  let c ← $ᵗ F
  match (dh_core.session M.operations (M.secret a) (M.secret b)).match with
  | .ok session =>
      adversary session.alice_public session.bob_public (M.key (c • M.generator))
  | _ => pure false

/-- The real session experiment and VCVio's real DDH experiment are equal as
probabilistic programs. -/
theorem realExperiment_eq_ddhRealExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) :
    realExperiment M adversary =
      DiffieHellman.ddhRealExperiment M.generator (ddhReduction M adversary) := by
  simp only [realExperiment, session_refines, DiffieHellman.ddhRealExperiment,
    ddhReduction, Aeneas.Std.Result.match.ok]

/-- The ideal session experiment equals VCVio's random DDH experiment. -/
theorem idealExperiment_eq_ddhRandomExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) :
    idealExperiment M adversary =
      DiffieHellman.ddhRandomExperiment M.generator (ddhReduction M adversary) := by
  simp only [idealExperiment, session_refines, DiffieHellman.ddhRandomExperiment,
    ddhReduction, Aeneas.Std.Result.match.ok]

/-- The Boolean statistical distance between the real and ideal session experiments. -/
noncomputable def sessionAdvantage (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : ℝ≥0∞ :=
  𝒟[realExperiment M adversary].boolDist 𝒟[idealExperiment M adversary]

/-- The session advantage equals the DDH advantage of the encoding reduction.
The primitive contracts are supplied by `M`. This theorem introduces no axiom
about a concrete cryptographic library. -/
theorem sessionAdvantage_eq_ddhAdvantage (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) :
    sessionAdvantage M adversary =
      DiffieHellman.ddhAdvantage M.generator (ddhReduction M adversary) := by
  simp only [sessionAdvantage, realExperiment_eq_ddhRealExperiment,
    idealExperiment_eq_ddhRandomExperiment, DiffieHellman.ddhAdvantage]

/-- A supplied DDH bound also bounds the session advantage.
The theorem neither proves DDH hardness nor restricts adversaries by running time.
An application must justify the hypothesis for its encoding reduction. -/
theorem sessionAdvantage_le_of_ddh (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) (ε : ℝ≥0∞)
    (hddh : DiffieHellman.ddhAdvantage M.generator (ddhReduction M adversary) ≤ ε) :
    sessionAdvantage M adversary ≤ ε := by
  rw [sessionAdvantage_eq_ddhAdvantage]
  exact hddh

end Experiments

end DhPoc
