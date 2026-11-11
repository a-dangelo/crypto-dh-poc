import DhPoc.Refinement
import VCVio.CryptoFoundations.HardnessAssumptions.DiffieHellman

/-!
# Exact game transport from the extracted Rust session to VCVio DDH

The games execute `dh_core.session`, the Aeneas output, rather than a mathematical
replacement. Every non-success result is mapped to `false`. PrimitiveModel's
explicit contracts prove these branches unreachable for encoded scalar inputs.
The ideal challenge is an independently sampled *encoded group element*, not a
uniform byte string. No encoding injectivity, hash/KDF assumption, authentication,
or security of a concrete curve implementation is asserted here.
-/

namespace DhPoc

open OracleComp OracleSpec ENNReal

variable {D S P K F G : Type} [Field F] [AddCommGroup G] [Module F G]

/-- The adversary observes the two public encodings and one key encoding. -/
abbrev SessionAdversary (P K : Type) := P → P → K → ProbComp Bool

/-- Lift the implementation's adversary to VCVio's group-level DDH interface.
The public generator is fixed in the model; the adversary need not receive it. -/
def ddhReduction (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : DiffieHellman.DDHAdversary F G :=
  fun _ A B T => adversary (M.point A) (M.point B) (M.key T)

section Experiments

variable [SampleableType F]

/-- Real passive experiment, invoking the extracted Rust session and exposing
Alice's computed key. The refinement theorem also proves Bob obtains this key. -/
def realExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : ProbComp Bool := do
  let a ← $ᵗ F
  let b ← $ᵗ F
  match (dh_core.session M.operations (M.secret a) (M.secret b)).match with
  | .ok session => adversary session.alice_public session.bob_public session.alice_key
  | _ => pure false

/-- Ideal passive experiment: run the same extracted session, but replace the
challenge by an independent encoding of `c • generator`. Failures remain explicit. -/
def idealExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : ProbComp Bool := do
  let a ← $ᵗ F
  let b ← $ᵗ F
  let c ← $ᵗ F
  match (dh_core.session M.operations (M.secret a) (M.secret b)).match with
  | .ok session =>
      adversary session.alice_public session.bob_public (M.key (c • M.generator))
  | _ => pure false

/-- Equality of complete probabilistic programs, not just success probabilities. -/
theorem realExperiment_eq_ddhRealExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) :
    realExperiment M adversary =
      DiffieHellman.ddhRealExperiment M.generator (ddhReduction M adversary) := by
  simp only [realExperiment, session_refines, DiffieHellman.ddhRealExperiment,
    ddhReduction, Aeneas.Std.Result.match.ok]

/-- The ideal experiment is exactly VCVio's random DDH experiment. -/
theorem idealExperiment_eq_ddhRandomExperiment (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) :
    idealExperiment M adversary =
      DiffieHellman.ddhRandomExperiment M.generator (ddhReduction M adversary) := by
  simp only [idealExperiment, session_refines, DiffieHellman.ddhRandomExperiment,
    ddhReduction, Aeneas.Std.Result.match.ok]

/-- VCVio's Boolean statistical distance between the implementation games. -/
noncomputable def sessionAdvantage (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) : ℝ≥0∞ :=
  𝒟[realExperiment M adversary].boolDist 𝒟[idealExperiment M adversary]

/-- Lossless reduction: the Rust-session distinguishing advantage equals DDH
advantage for the explicit encoding reduction. The primitive contracts are the
fields of `M`, not axioms about a concrete cryptographic library. -/
theorem sessionAdvantage_eq_ddhAdvantage (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) :
    sessionAdvantage M adversary =
      DiffieHellman.ddhAdvantage M.generator (ddhReduction M adversary) := by
  simp only [sessionAdvantage, realExperiment_eq_ddhRealExperiment,
    idealExperiment_eq_ddhRandomExperiment, DiffieHellman.ddhAdvantage]

/-- A precise conditional security bound for any supplied DDH bound. This does
not assert DDH hardness or place an unformalized efficiency restriction on all
adversaries. A concrete application must justify this hypothesis for its reduction. -/
theorem sessionAdvantage_le_of_ddh (M : PrimitiveModel D S P K F G)
    (adversary : SessionAdversary P K) (ε : ℝ≥0∞)
    (hddh : DiffieHellman.ddhAdvantage M.generator (ddhReduction M adversary) ≤ ε) :
    sessionAdvantage M adversary ≤ ε := by
  rw [sessionAdvantage_eq_ddhAdvantage]
  exact hddh

end Experiments

end DhPoc
