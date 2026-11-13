import HashCommitment.Bridge.HashCommitment

/-!
# Security transferred to the extracted implementation

The implementation sampler is the finite interpretation proved equal to generated code.
The verifier reads the generated result. Its totality follows from `HashRefines`.
Collision resistance is a security assumption; hash refinement is a separate functional
assumption. Neither is supplied by Rust's `CryptoRng` marker.
-/
namespace HashCommitment
open Aeneas Aeneas.Std OracleComp OracleSpec
open Probability Probability.Program Bridge Model CommitmentScheme CollisionResistance
variable {K H : Type}

/-- Read a terminating Boolean result. Refinement excludes the other cases below. -/
def resultBoolean (r : Result Bool) : Bool :=
  match r.match with
  | .ok b => b
  | _ => false

/-- VCV-io interface to the finite implementation semantics, with decoded openings. -/
def implementationScheme (hashInst : Extracted.KeyedHash H K)
    (keygen : ProbComp K) (hashFn : K → Bytes32 → Bytes 32 → Bytes32) :
    CommitmentScheme K Bytes32 Bytes32 (Bytes 32) where
  setup := keygen
  commit key msg := do
    let ((digest, opening), _) ← (commitProgram hashFn key msg).toProb
    pure (digest, toBytes opening)
  verify key msg digest opening :=
    resultBoolean (Extracted.verify hashInst key msg digest (ofBytes opening))

/-- Decode an implementation result without deleting exceptional outcomes. -/
def decodeCommitOutcome : Probability.Outcome ((Bytes32 × Bytes32) × Unit) →
    Probability.Outcome (Bytes32 × Bytes 32)
  | .success ((digest, opening), _) => .success (digest, toBytes opening)
  | .failure e => .failure e
  | .divergence => .divergence
  | .cutoff => .cutoff

/-- The scheme sampler is the decoded law of the actual generated commitment.
The refinement assumption concerns the hash implementation, not its security. -/
theorem implementation_commit_extracted (hashInst : Extracted.KeyedHash H K)
    (keygen : ProbComp K) (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg : Bytes32) :
    (do
      let output ← Probability.interpret 33
        (Extracted.commit hashInst idealRng idealCryptoRng key msg ())
      pure (decodeCommitOutcome output)) =
    (do
      let output ← (implementationScheme hashInst keygen hashFn).commit key msg
      pure (Probability.Outcome.success output)) := by
  rw [commit_joint_law hashInst hashFn hH key msg 33 (commit_depth hashFn key msg)]
  simp [implementationScheme, decodeCommitOutcome]

/-- The implementation's commitment distribution is the model's entire pair law. -/
theorem implementation_commit_eq (hashInst : Extracted.KeyedHash H K)
    (keygen : ProbComp K) (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (key : K) (msg : Bytes32) :
    (implementationScheme hashInst keygen hashFn).commit key msg =
      (Model.scheme keygen hashFn).commit key msg := by
  simp only [implementationScheme, commitProgram, Program.toProb_map,
    LawfulMonad.bind_assoc, LawfulMonad.pure_bind, toBytes_ofBytes]
  rw [bytesProgram_toProb]
  unfold Model.scheme Model.commit Model.randomBytes
  simp only [simulateQ_bind, simulateQ_spec_query, simulateQ_pure]
  rfl

/-- Functional and probabilistic refinement give equality of VCV-io scheme interfaces. -/
theorem implementation_eq_model (hashInst : Extracted.KeyedHash H K)
    (keygen : ProbComp K) (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) :
    implementationScheme hashInst keygen hashFn = Model.scheme keygen hashFn := by
  have hc := funext fun key => funext fun msg =>
    implementation_commit_eq hashInst keygen hashFn key msg
  have hv : (implementationScheme hashInst keygen hashFn).verify =
      (Model.scheme keygen hashFn).verify := by
    funext key msg digest opening
    simp [implementationScheme, verify_refines hashInst hashFn hH,
      resultBoolean, Model.scheme, toBytes_ofBytes]
  have hs : (implementationScheme hashInst keygen hashFn).setup =
      (Model.scheme keygen hashFn).setup := rfl
  cases h : implementationScheme hashInst keygen hashFn
  cases hm : Model.scheme keygen hashFn
  simp only [h, hm] at hc hv hs
  simp only [CommitmentScheme.mk.injEq]
  exact ⟨hs, hc, hv⟩

/-- Honest execution calls the generated commitment, then the generated verifier. -/
def honestExecution (hashInst : Extracted.KeyedHash H K) (key : K) (msg : Bytes32) :
    Result Bool := do
  let ((digest, opening), _) ← Extracted.commit hashInst idealRng idealCryptoRng key msg ()
  Extracted.verify hashInst key msg digest opening

/-- The finite witness retains the sampling events even though the answer is constant. -/
def honestProgram : Program Bool := (bytesProgram 32).map (fun _ => true)

/-- Every honest sampled opening is accepted by the actual generated verifier. -/
theorem honest_representation (hashInst : Extracted.KeyedHash H K)
    (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg : Bytes32) :
    honestExecution hashInst key msg = honestProgram.toResult := by
  unfold honestExecution
  rw [commit_representation hashInst hashFn hH]
  simp only [commitProgram, Program.toResult_map, bind_tc_eq, Aeneas.Std.bind_assoc, bind_ok]
  unfold honestProgram
  rw [Program.toResult_map]
  congr 1
  funext opening
  simp [verify_refines hashInst hashFn hH, Model.verify]

/-- The probability of acceptance is one; cutoff and other exceptional outcomes have zero mass. -/
theorem honest_correct (hashInst : Extracted.KeyedHash H K)
    (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn) (key : K) (msg : Bytes32) :
    letI : MeasurableSpace (Probability.Outcome Bool) := ⊤
    𝒟[Probability.interpret 33 (honestExecution hashInst key msg)]
      {Probability.Outcome.success true} = 1 := by
  let : MeasurableSpace (Probability.Outcome Bool) := ⊤
  rw [Probability.interpret_eq_of_representation _ honestProgram
    (honest_representation hashInst hashFn hH key msg) 33
    (by simpa [honestProgram] using bytesProgram_depth 32)]
  simp only [honestProgram, Program.toProb_map, bytesProgram_toProb,
    LawfulMonad.bind_assoc, LawfulMonad.pure_bind]
  rw [OracleComp.evalDist_bind_const]
  simp

/-- Binding reduces to keyed collision resistance of the specified hash family.
This experiment does not call `commit`; randomness is justified separately by the joint law. -/
theorem implementation_binding (hashInst : Extracted.KeyedHash H K)
    (keygen : ProbComp K) (hashFn : K → Bytes32 → Bytes 32 → Bytes32)
    (hH : HashRefines hashInst hashFn)
    (A : BindingAdversary K Bytes32 Bytes32 (Bytes 32)) :
    bindingAdvantage (implementationScheme hashInst keygen hashFn) A ≤
      keyedCRAdvantage (Model.hashFamily keygen hashFn)
        (bindingAdversary_toKeyedCRAdversary A) := by
  rw [implementation_eq_model hashInst keygen hashFn hH]
  exact Model.binding keygen hashFn A

end HashCommitment
