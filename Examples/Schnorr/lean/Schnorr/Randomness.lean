import Schnorr.Refinement
import VCVio.OracleComp.SimSemantics.SimulateQ

/-! One sampling program, two interpretations. The runtime theorem preserves the
entire extracted `Result`, including failure, divergence, and the updated RNG
state. The ideal theorem is a separate model with fresh uniform samples. Nothing
here asserts that a concrete RNG has the ideal sampling law. -/
namespace SchnorrProof.Randomness

open Aeneas.Std OracleComp

variable {D S P R : Type}

/-- A single effect: request the next scalar. Sequencing requests remains visible
in the free computation, so handlers also interpret composed sampling programs. -/
abbrev ScalarSpec (S : Type) : OracleSpec Unit := Unit →ₒ S

/-- Sample a nonce and call the actual extracted deterministic commitment. Its
`Result` remains an observed value until the runtime boundary flattens it. -/
def commitmentProgram (ops : schnorr_core.Group D S P) :
    OracleComp (ScalarSpec S) (Result (P × S)) := do
  let nonce ← liftM ((ScalarSpec S).query ())
  pure (do
    let commitment ← schnorr_core.commit ops nonce
    pure (commitment, nonce))

/-- Interpret each sampling effect using the extracted mutable RNG interface. -/
def runtimeSampler (rng : schnorr_core.ScalarRng R S) :
    QueryImpl (ScalarSpec S) (StateT R Result) :=
  fun _ => rng.sample

/-- Flatten arithmetic failure/divergence together with RNG failure/divergence
at the boundary, retaining the final state on successful execution. -/
def runRuntime (rng : schnorr_core.ScalarRng R S)
    (program : OracleComp (ScalarSpec S) (Result α)) (state : R) : Result (α × R) := do
  let (outcome, state') ← (simulateQ (runtimeSampler rng) program).run state
  let value ← outcome
  pure (value, state')

/-- Exact runtime equality, for every RNG implementation and initial state.
No termination, success, independence, or distributional premise is needed. -/
theorem runtime_commitment_eq (ops : schnorr_core.Group D S P)
    (rng : schnorr_core.ScalarRng R S) (state : R) :
    runRuntime rng (commitmentProgram ops) state =
      schnorr_core.commit_random ops rng state := by
  simp only [runRuntime, commitmentProgram, simulateQ_bind, simulateQ_spec_query,
    simulateQ_pure, StateT.run_bind, StateT.run_pure]
  simp only [runtimeSampler, StateT.run, schnorr_core.commit_random, bind_tc_eq,
    Aeneas.Std.bind_assoc, pure_tc_eq, bind_ok]
  apply congrArg (Aeneas.Std.bind (rng.sample state))
  funext pair
  rcases pair with ⟨nonce, state'⟩
  simp [Aeneas.Std.bind_assoc]


/-- Every ideal query draws a new independent scalar from the mathematical
uniform sampler, then encodes it into the extracted scalar representation. -/
def idealSampler {F : Type} [SampleableType F] (encode : F → S) :
    QueryImpl (ScalarSpec S) ProbComp :=
  fun _ => encode <$> ($ᵗ F)

/-- Ideal interpretation is the extracted commitment applied to an ideal nonce.
This equality still observes any arithmetic error as a `Result` value. -/
theorem ideal_commitment_eq {F : Type} [SampleableType F]
    (ops : schnorr_core.Group D S P) (encode : F → S) :
    simulateQ (idealSampler encode) (commitmentProgram ops) =
      (do
        let nonce ← $ᵗ F
        pure (do
          let commitment ← schnorr_core.commit ops (encode nonce)
          pure (commitment, encode nonce))) := by
  simp [commitmentProgram, idealSampler]

/-- With the independent arithmetic refinement contract, ideal commitment
sampling is exactly uniform scalar sampling followed by scalar multiplication. -/
theorem ideal_commitment_refines {F G : Type} [Field F] [AddCommGroup G]
    [Module F G] [DecidableEq G] [SampleableType F] {g : G}
    (M : SchnorrProof.PrimitiveModel F G D S P g) :
    simulateQ (idealSampler M.scalar) (commitmentProgram M.ops) =
      (do
        let nonce ← $ᵗ F
        pure (Result.ok (M.point (nonce • g), M.scalar nonce))) := by
  rw [ideal_commitment_eq]
  simp [SchnorrProof.commit_eq, pure_tc_eq]

end SchnorrProof.Randomness
